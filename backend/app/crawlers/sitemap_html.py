"""Salesforce Commerce Cloud has no public product feed the way Shopify has
`/products.json`, so this discovers product URLs from the brand's sitemap and
scrapes each product page instead.

The GA4 tracking blob (`dataLayerEvent`) every SFCC page embeds for its own
analytics is the data source — a site breaking its own analytics is a bigger
problem for them than for us, so it's a steadier target than incidental page
markup. It only carries one price per page, so a product here is always a
single variant: no per-size or per-color rows the way Shopify gives us.

A delisted product is recognised by that blob, not by its URL: SFCC 301s the
dead product back to its collection page, whose blob carries `impressions`
and no `detail`, so the page simply yields no product. Sites that 404 instead
raise, and the caller skips them.

Images are not in the tracking blob and are lazy-loaded, so the gallery's
`data-high-src` is the source: the `src` attribute holds a base64 placeholder
until JavaScript runs, and `data-src` carries display-size query parameters.
"""

import json
import re
from collections.abc import Iterator
from decimal import Decimal
from urllib.parse import urljoin

from app.crawlers.base import NormalizedProduct, NormalizedVariant, PoliteFetcher

_SITEMAP_LOC_RE = re.compile(r"<loc>([^<]+)</loc>")
_DATALAYER_RE = re.compile(r"dataLayerEvent\s*=\s*(\{.*?\});", re.DOTALL)
_NOTIFY_ME_RE = re.compile(r'class="notifyMe-wrapper([^"]*)"')
_IMG_TAG_RE = re.compile(r"<img [^>]*>")
_HIGH_SRC_RE = re.compile(r'data-high-src="([^"]+)"')
_LD_JSON_RE = re.compile(
    r'<script type="application/ld\+json">(.*?)</script>', re.DOTALL
)


def fetch_products(sitemap_url: str, fetcher: PoliteFetcher) -> Iterator[NormalizedProduct]:
    """Yield every still-listed product from a Salesforce Commerce Cloud sitemap."""
    xml = fetcher.get_text(sitemap_url)
    for url in _SITEMAP_LOC_RE.findall(xml):
        if "/products/" not in url:
            continue  # the sitemap also lists category/collection pages
        product = fetch_one_product(url, fetcher)
        if product is not None:
            yield product


def fetch_one_product(url: str, fetcher: PoliteFetcher) -> NormalizedProduct | None:
    """Re-check a single product (US-13's hourly watch alerts) without
    re-walking the sitemap."""
    html, final_url = fetcher.get_html(url)
    return _parse_product_page(html, final_url)


def _gallery_image_urls(html: str, url: str) -> list[str]:
    """Full-resolution product images, in the order the gallery shows them.

    Two sources because SFCC stores differ: Khaadi publishes schema.org
    `Product` JSON-LD listing its images, Sapphire publishes no `Product` node
    at all and keeps them in the lazy-loading gallery. JSON-LD comes first
    where it exists — it is the site stating its own product data rather than
    markup we inferred. Relative paths are resolved against the page.
    """
    return [
        urljoin(url, image)
        for image in (_ld_json_images(html) or _lazy_gallery_images(html))
    ]


def _ld_json_images(html: str) -> list[str]:
    for block in _LD_JSON_RE.findall(html):
        try:
            data = json.loads(block.strip())
        except json.JSONDecodeError:
            continue
        if not isinstance(data, dict) or data.get("@type") != "Product":
            continue
        images = data.get("image")
        if isinstance(images, str):
            return [images]
        if isinstance(images, list):
            return [image for image in images if isinstance(image, str)]
    return []


def _lazy_gallery_images(html: str) -> list[str]:
    """Scoped to the gallery's own `pdp-image` class rather than every
    `data-high-src` on the page, so a recommendation carousel cannot attach
    another product's photos to this one."""
    urls: list[str] = []
    for tag in _IMG_TAG_RE.findall(html):
        if "pdp-image" not in tag:
            continue
        match = _HIGH_SRC_RE.search(tag)
        if match is not None and match.group(1) not in urls:
            urls.append(match.group(1))
    return urls


def _parse_product_page(html: str, url: str) -> NormalizedProduct | None:
    match = _DATALAYER_RE.search(html)
    if match is None:
        return None
    try:
        raw = json.loads(match.group(1))["ecommerce"]["detail"]["products"][0]
    except (json.JSONDecodeError, KeyError, IndexError, TypeError):
        return None

    raw_price = raw.get("price")
    if raw_price is None:
        return None
    price = Decimal(str(raw_price))
    raw_compare_at = raw.get("compare_price")
    compare_at = Decimal(str(raw_compare_at)) if raw_compare_at is not None else None

    notify_me = _NOTIFY_ME_RE.search(html)
    # The button is hidden (`d-none`) unless the item is out of stock.
    in_stock = notify_me is None or "d-none" in notify_me.group(1)

    return NormalizedProduct(
        external_id=str(raw["id"]),
        source_url=url,
        title=raw.get("name", ""),
        category=raw.get("category") or None,
        image_urls=_gallery_image_urls(html, url),
        variants=[
            NormalizedVariant(
                external_id=str(raw["id"]),
                price=price,
                compare_at_price=compare_at if compare_at != price else None,
                in_stock=in_stock,
            )
        ],
    )
