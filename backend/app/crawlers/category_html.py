"""Salesforce Commerce Cloud stores that publish no product sitemap.

Khaadi's sitemap lists category pages, not products, so product URLs are
discovered by paging each category's own listing. The listing renders its
tiles server-side; the AJAX grid that fills the page afterwards lives under
`/on/demandware.store/`, which robots.txt disallows, so the rendered HTML is
both the only source and the allowed one.

Product pages here are ordinary SFCC pages, so `sitemap_html` parses them.
"""

import re
from collections.abc import Iterator
from urllib.parse import urljoin, urlparse

import httpx

from app.crawlers import sitemap_html
from app.crawlers.base import NormalizedProduct, PoliteFetcher

# 96 keeps a listing page around 3MB; the site also serves more per request,
# but each page is already one request instead of four.
PAGE_SIZE = 96
_PDP_LINK_RE = re.compile(r'<a class="link plpRedirectPdp" href="([^"?]+)')


def fetch_products(sitemap_url: str, fetcher: PoliteFetcher) -> Iterator[NormalizedProduct]:
    """Yield every product reachable from the sitemap's top-level categories."""
    seen: set[str] = set()
    for category_url in _category_urls(sitemap_url, fetcher):
        for product_url in _product_urls_in(category_url, fetcher):
            if product_url in seen:
                continue
            seen.add(product_url)
            product = _fetch_product(product_url, fetcher)
            if product is not None:
                yield product


def _category_urls(sitemap_url: str, fetcher: PoliteFetcher) -> Iterator[str]:
    """The sitemap's top-level sections.

    Sub-categories are subsets of the section above them, so paging the
    sections alone covers the catalog without fetching the same product out of
    several overlapping listings. The sitemap also lists non-catalog pages
    (`/checkout`, `/404`); those are either disallowed or simply list no
    products, so they cost one request and drop out on their own.
    """
    xml = fetcher.get_text(sitemap_url)
    for url in sitemap_html._SITEMAP_LOC_RE.findall(xml):
        path = urlparse(url).path.strip("/")
        if path and "/" not in path and fetcher.can_fetch(url):
            yield url


def _product_urls_in(category_url: str, fetcher: PoliteFetcher) -> Iterator[str]:
    start = 0
    while True:
        page = f"{category_url}?start={start}&sz={PAGE_SIZE}"
        try:
            html = fetcher.get_text(page)
        except httpx.HTTPStatusError:
            return  # not a listing at all, or paged past the end
        paths = list(dict.fromkeys(_PDP_LINK_RE.findall(html)))
        for path in paths:
            yield urljoin(category_url, path)
        if len(paths) < PAGE_SIZE:
            return  # a short page is the last one
        start += PAGE_SIZE


def _fetch_product(url: str, fetcher: PoliteFetcher) -> NormalizedProduct | None:
    """A listed product that 404s has been delisted between the listing and
    now — that is a skip, not a failed crawl."""
    try:
        return sitemap_html.fetch_one_product(url, fetcher)
    except httpx.HTTPStatusError as error:
        if error.response.status_code == 404:
            return None
        raise
