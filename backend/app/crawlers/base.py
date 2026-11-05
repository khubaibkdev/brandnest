import time
import urllib.robotparser
from dataclasses import dataclass, field
from decimal import Decimal
from urllib.parse import urlparse

import httpx

from app.config import settings

SERVER_ERROR_BACKOFF_SECONDS = 30
RATE_LIMIT_WAIT_CAP_SECONDS = 120
# ~1 quota window per page on strict stores (measured 2026-07-25); 30 waits ≈ 30 min/brand,
# comfortably inside the nightly 01:00–05:00 crawl window.
MAX_RATE_LIMIT_WAITS_PER_ORIGIN = 30


@dataclass
class NormalizedVariant:
    external_id: str
    price: Decimal
    compare_at_price: Decimal | None
    in_stock: bool
    size: str | None = None
    color: str | None = None


@dataclass
class NormalizedProduct:
    external_id: str
    source_url: str
    title: str
    description: str | None = None
    category: str | None = None
    tags: list[str] = field(default_factory=list)
    image_urls: list[str] = field(default_factory=list)
    variants: list[NormalizedVariant] = field(default_factory=list)


class PoliteFetcher:
    """HTTP client enforcing the CRAWLER_PLAYBOOK rules: honest UA, robots.txt,
    fixed delay between requests, backoff-and-stop on 403/429."""

    def __init__(self) -> None:
        self.client = httpx.Client(
            headers={"User-Agent": settings.crawler_user_agent},
            timeout=30,
            follow_redirects=True,
        )
        self._robots: dict[str, urllib.robotparser.RobotFileParser] = {}
        self._last_request_at = 0.0
        self._rate_limit_waits: dict[str, int] = {}

    def _robots_for(self, url: str) -> urllib.robotparser.RobotFileParser:
        origin = f"{urlparse(url).scheme}://{urlparse(url).netloc}"
        if origin not in self._robots:
            # Fetch with our own client: RobotFileParser.read() uses the
            # Python-urllib UA, which bot protection rejects — and a 403 there
            # would wrongly mark the whole site disallowed.
            parser = urllib.robotparser.RobotFileParser()
            try:
                response = self.client.get(f"{origin}/robots.txt")
                if response.status_code >= 500:
                    parser.disallow_all = True
                elif response.status_code >= 400:
                    parser.allow_all = True  # no robots.txt → no restrictions
                else:
                    parser.parse(response.text.splitlines())
            except httpx.HTTPError:
                parser.disallow_all = True  # unreachable → be conservative
            self._robots[origin] = parser
        return self._robots[origin]

    def _wait_politely(self) -> None:
        elapsed = time.monotonic() - self._last_request_at
        if elapsed < settings.crawler_delay_seconds:
            time.sleep(settings.crawler_delay_seconds - elapsed)
        self._last_request_at = time.monotonic()

    def get_json(self, url: str) -> dict:
        return self._fetch(url).json()

    def get_text(self, url: str) -> str:
        return self._fetch(url).text

    def get_html(self, url: str) -> tuple[str, str]:
        """Returns `(html, final_url)` — `final_url` differs from `url` when
        the site redirected elsewhere, e.g. Salesforce Commerce Cloud bouncing
        a delisted product back to its collection page."""
        response = self._fetch(url)
        return response.text, str(response.url)

    def can_fetch(self, url: str) -> bool:
        """Whether robots.txt allows this URL. Discovery uses it to pass over a
        disallowed page quietly — reaching one is expected when URLs come from a
        site's own sitemap, and it is not the site refusing us the way a 403 is."""
        return self._robots_for(url).can_fetch(settings.crawler_user_agent, url)

    def _fetch(self, url: str) -> httpx.Response:
        if not self.can_fetch(url):
            raise CrawlBlocked(f"robots.txt disallows {url}")
        origin = f"{urlparse(url).scheme}://{urlparse(url).netloc}"
        server_error_retried = False
        while True:
            self._wait_politely()
            response = self.client.get(url)
            if response.status_code == 429:
                retry_after = self._parse_retry_after(response)
                waits_used = self._rate_limit_waits.get(origin, 0)
                if retry_after is not None and waits_used < MAX_RATE_LIMIT_WAITS_PER_ORIGIN:
                    # Quota-style limiting: the server says when to resume — honor it.
                    self._rate_limit_waits[origin] = waits_used + 1
                    time.sleep(min(retry_after, RATE_LIMIT_WAIT_CAP_SECONDS))
                    continue
                raise CrawlBlocked(f"HTTP 429 from {url} (wait budget exhausted)")
            if response.status_code == 403:
                raise CrawlBlocked(f"HTTP 403 from {url}")
            if response.status_code >= 500:
                if not server_error_retried:
                    server_error_retried = True
                    time.sleep(SERVER_ERROR_BACKOFF_SECONDS)
                    continue
                raise CrawlBlocked(f"HTTP {response.status_code} (server error) from {url}")
            response.raise_for_status()
            return response

    @staticmethod
    def _parse_retry_after(response: httpx.Response) -> int | None:
        value = response.headers.get("Retry-After")
        try:
            return int(value) if value else None
        except ValueError:
            return None

    def close(self) -> None:
        self.client.close()


class CrawlBlocked(Exception):
    """Raised when a site refuses us; the caller must stop crawling this brand."""
