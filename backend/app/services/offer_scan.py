"""Weekly hunt for bank discounts announced on the brands' own sites (US-3/US-5).

Why here and not on the banks' sites: their public discount programmes are
dining, not fashion. MCB's — the only one of our five that publishes a
browsable list — carries exactly one Lifestyle merchant and no apparel brand at
all (checked 2026-09-05). Bank x fashion offers in Pakistan surface as
time-boxed campaigns the *brand* announces, so the brand's own pages are the
source worth watching.

Nothing found here reaches a shopper. Every hit is filed `needs_verification`
with the page it came from as proof, and the desk's existing rule stands: a
human with a name has to verify it (decision of 2026-07-27).
"""

import logging
import re
from datetime import date
from urllib.parse import urljoin, urlparse

from sqlalchemy import select

from app.crawlers.base import CrawlBlocked, PoliteFetcher
from app.db import get_session
from app.models import Bank, BankOffer, Brand

logger = logging.getLogger(__name__)

# How these banks are actually written in Pakistani retail copy. Kept explicit
# rather than derived from the name: deriving would produce "Standard", which
# matches "standard delivery" and "standard size" on every clothing site.
BANK_ALIASES = {
    "hbl": ["HBL", "Habib Bank"],
    "mcb": ["MCB"],
    "ubl": ["UBL"],
    "meezan": ["Meezan"],
    "bank-alfalah": ["Alfalah"],
    "standard-chartered": ["Standard Chartered", "SCB"],
}

# A bank offer is a discount, not a fabric composition. Two digits only, so
# "100% cotton" — on every product page we crawl — cannot match at all.
_PERCENT_RE = re.compile(r"\b(\d{1,2})\s*%")
MIN_PCT = 5
MAX_PCT = 75

# How close the bank's name has to sit to the number to be talking about it.
PROXIMITY_CHARS = 120

# Pages worth fetching per brand beyond the homepage.
_OFFER_LINK_RE = re.compile(r"discount|offer|promo|bank|deal", re.I)
# Themes ship files like `component-discounts.css`, which match the keyword and
# are never an announcement. Seen fetching four of them on the first live run.
_ASSET_SUFFIXES = (".css", ".js", ".json", ".png", ".jpg", ".jpeg", ".svg", ".webp", ".gif", ".pdf", ".xml")
MAX_PAGES_PER_BRAND = 3

SOURCE = "auto-scan"


def aliases_for(bank: Bank) -> list[str]:
    return [bank.name, *BANK_ALIASES.get(bank.slug, [])]


def find_offers(text: str, banks: list[Bank]) -> list[tuple[Bank, int, str]]:
    """Every (bank, percentage, snippet) this text plausibly announces.

    Word boundaries are not optional here: without them "UBL" matches inside
    "DOUBLE" and "Alfalah" inside a customer named Ullah — both seen for real
    while looking for exactly this.
    """
    found: list[tuple[Bank, int, str]] = []
    for match in _PERCENT_RE.finditer(text):
        percent = int(match.group(1))
        if not MIN_PCT <= percent <= MAX_PCT:
            continue
        start = max(0, match.start() - PROXIMITY_CHARS)
        window = text[start : match.end() + PROXIMITY_CHARS]
        for bank in banks:
            patterns = (rf"\b{re.escape(alias)}\b" for alias in aliases_for(bank))
            if any(re.search(pattern, window, re.I) for pattern in patterns):
                found.append((bank, percent, " ".join(window.split())))
                break
    return found


def readable_text(html: str) -> str:
    without_code = re.sub(r"(?is)<(script|style|noscript)[^>]*>.*?</\1>", " ", html)
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", without_code))


def pages_to_scan(brand: Brand, fetcher: PoliteFetcher) -> list[tuple[str, str]]:
    """The brand's homepage, plus the offer-ish pages it links to."""
    try:
        html, url = fetcher.get_html(brand.website_url)
    except (CrawlBlocked, Exception):
        logger.info("%s: homepage unreadable, skipped", brand.slug)
        return []

    pages = [(url, readable_text(html))]
    candidates = []
    for href, label in re.findall(r'href="([^"]+)"[^>]*>([^<]{0,60})', html):
        if href.startswith(("#", "mailto:", "tel:", "javascript:")):
            continue
        if not (_OFFER_LINK_RE.search(href) or _OFFER_LINK_RE.search(label)):
            continue
        # `urljoin` against the page we actually landed on, so protocol-relative
        # hrefs (`//host/path`) resolve to their own host instead of being
        # pasted onto ours — which produced `brand.pk/brand.pk/...` 404s.
        target = urljoin(url, href)
        if urlparse(target).path.lower().endswith(_ASSET_SUFFIXES):
            continue
        candidates.append(target)

    for target in list(dict.fromkeys(candidates))[:MAX_PAGES_PER_BRAND]:
        try:
            page_html, page_url = fetcher.get_html(target)
        except Exception:
            continue
        pages.append((page_url, readable_text(page_html)))
    return pages


def _already_filed(session, bank_id: int, brand_id: int, percent: int) -> bool:
    """The same offer found again next week is the same offer, not a new one —
    and a rejected one must not come back either."""
    return session.scalar(
        select(BankOffer.id).where(
            BankOffer.bank_id == bank_id,
            BankOffer.brand_id == brand_id,
            BankOffer.discount_pct == percent,
        )
    ) is not None


def scan_brand(session, brand: Brand, banks: list[Bank], fetcher: PoliteFetcher) -> int:
    filed = 0
    for url, text in pages_to_scan(brand, fetcher):
        for bank, percent, snippet in find_offers(text, banks):
            if _already_filed(session, bank.id, brand.id, percent):
                continue
            session.add(
                BankOffer(
                    bank_id=bank.id,
                    brand_id=brand.id,
                    discount_pct=percent,
                    proof_url=url[:500],
                    status="needs_verification",
                    source=SOURCE,
                    valid_from=date.today(),
                )
            )
            session.flush()
            filed += 1
            logger.info("%s: %s %d%% — %s", brand.slug, bank.name, percent, snippet[:160])
    return filed


def run_offer_scan() -> dict:
    """Worker entry point: sweep every active brand once."""
    session = get_session()
    fetcher = PoliteFetcher()
    stats = {"brands": 0, "filed": 0}
    try:
        banks = session.scalars(select(Bank)).all()
        brands = session.scalars(
            select(Brand).where(Brand.is_active).order_by(Brand.name)
        ).all()
        for brand in brands:
            stats["brands"] += 1
            try:
                stats["filed"] += scan_brand(session, brand, banks, fetcher)
                session.commit()
            except Exception:
                session.rollback()
                logger.exception("%s: offer scan failed", brand.slug)
    finally:
        fetcher.close()
        session.close()
    logger.info("offer scan: %s", stats)
    return stats
