"""US-8: discovering products from category listings, for Salesforce Commerce
Cloud stores whose sitemap lists categories rather than products (Khaadi).
Product-page parsing itself is `sitemap_html`'s and tested there."""

import httpx
import pytest

from app.crawlers import category_html

BASE = "https://pk.khaadi.com"


def _tile(path: str) -> str:
    """The listing's own link markup, including the `?source=plp` query that
    robots.txt disallows and so must not survive into the fetched URL."""
    return f'<a class="link plpRedirectPdp" href="{path}?source=plp"><h2>X</h2></a>'


def _listing(paths: list[str]) -> str:
    return "<html><body>" + "".join(_tile(p) for p in paths) + "</body></html>"


class FakeFetcher:
    """Records what was requested so the tests can assert on crawl shape, not
    just on the products that come back."""

    def __init__(self, pages: dict[str, str], allowed: set[str] | None = None):
        self.pages = pages
        self.allowed = allowed
        self.requested: list[str] = []

    def can_fetch(self, url: str) -> bool:
        return self.allowed is None or url in self.allowed

    def get_text(self, url: str) -> str:
        self.requested.append(url)
        if url not in self.pages:
            raise httpx.HTTPStatusError(
                "404", request=httpx.Request("GET", url),
                response=httpx.Response(404, request=httpx.Request("GET", url)),
            )
        return self.pages[url]


SITEMAP = f"""<urlset>
  <loc>{BASE}/ready-to-wear/</loc>
  <loc>{BASE}/western/bottoms/trousers/</loc>
  <loc>{BASE}/checkout</loc>
</urlset>"""


def _category_urls(pages, allowed=None):
    fetcher = FakeFetcher(pages, allowed)
    return list(category_html._category_urls(f"{BASE}/sitemap.xml", fetcher)), fetcher


def test_only_top_level_sections_are_paged():
    """Sub-categories are subsets of the section above them, so paging both
    would fetch the same product out of two listings."""
    urls, _ = _category_urls({f"{BASE}/sitemap.xml": SITEMAP})

    assert urls == [f"{BASE}/ready-to-wear/", f"{BASE}/checkout"]


def test_a_disallowed_sitemap_entry_is_passed_over_quietly():
    """A site's sitemap listing its own robots-disallowed pages is normal, and
    must not read as the site refusing us."""
    urls, _ = _category_urls(
        {f"{BASE}/sitemap.xml": SITEMAP}, allowed={f"{BASE}/ready-to-wear/"}
    )

    assert urls == [f"{BASE}/ready-to-wear/"]


def test_the_disallowed_source_query_is_stripped_from_product_urls():
    """`Disallow: /*source=` — following the listing's own href verbatim would
    put us straight onto a disallowed URL."""
    pages = {f"{BASE}/ready-to-wear/?start=0&sz={category_html.PAGE_SIZE}":
             _listing(["/kurta/ABC.html"])}
    fetcher = FakeFetcher(pages)

    urls = list(category_html._product_urls_in(f"{BASE}/ready-to-wear/", fetcher))

    assert urls == [f"{BASE}/kurta/ABC.html"]


def test_paging_stops_on_a_short_page():
    size = category_html.PAGE_SIZE
    full = [f"/p/{i}.html" for i in range(size)]
    pages = {
        f"{BASE}/c/?start=0&sz={size}": _listing(full),
        f"{BASE}/c/?start={size}&sz={size}": _listing(["/p/last.html"]),
    }
    fetcher = FakeFetcher(pages)

    urls = list(category_html._product_urls_in(f"{BASE}/c/", fetcher))

    assert len(urls) == size + 1
    assert urls[-1] == f"{BASE}/p/last.html"
    # Stopped rather than asking for a third page.
    assert len(fetcher.requested) == 2


def test_a_category_that_is_not_a_listing_yields_nothing():
    """`/checkout` and `/404` are in the sitemap too; they 404 or list no
    products, and neither should abort the brand's crawl."""
    fetcher = FakeFetcher({})

    assert list(category_html._product_urls_in(f"{BASE}/checkout", fetcher)) == []


def test_a_product_that_404s_between_listing_and_fetch_is_skipped(monkeypatch):
    def raise_404(url, fetcher):
        raise httpx.HTTPStatusError(
            "404", request=httpx.Request("GET", url),
            response=httpx.Response(404, request=httpx.Request("GET", url)),
        )

    monkeypatch.setattr(category_html.sitemap_html, "fetch_one_product", raise_404)

    assert category_html._fetch_product(f"{BASE}/kurta/ABC.html", FakeFetcher({})) is None


def test_a_server_error_on_a_product_is_not_swallowed(monkeypatch):
    """Only 404 means delisted. A 500 is the site in trouble and must reach
    the caller's backoff rather than looking like an empty catalog."""
    def raise_500(url, fetcher):
        raise httpx.HTTPStatusError(
            "500", request=httpx.Request("GET", url),
            response=httpx.Response(500, request=httpx.Request("GET", url)),
        )

    monkeypatch.setattr(category_html.sitemap_html, "fetch_one_product", raise_500)

    with pytest.raises(httpx.HTTPStatusError):
        category_html._fetch_product(f"{BASE}/kurta/ABC.html", FakeFetcher({}))
