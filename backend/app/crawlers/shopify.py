from collections.abc import Iterator
from decimal import Decimal

from app.crawlers.base import NormalizedProduct, NormalizedVariant, PoliteFetcher

PAGE_SIZE = 250


def fetch_products(base_url: str, fetcher: PoliteFetcher) -> Iterator[NormalizedProduct]:
    """Yield every product from a Shopify store's public /products.json."""
    page = 1
    while True:
        data = fetcher.get_json(f"{base_url}/products.json?limit={PAGE_SIZE}&page={page}")
        products = data.get("products", [])
        if not products:
            return
        for raw in products:
            yield _normalize(base_url, raw)
        page += 1


def fetch_one_product(product_url: str, fetcher: PoliteFetcher) -> NormalizedProduct | None:
    """Re-check a single product (US-13's hourly watch alerts) via the same
    per-product `.json` endpoint Shopify's own storefront JS uses — far
    cheaper than paging through the whole catalog to find one item."""
    base_url = product_url.split("/products/")[0]
    data = fetcher.get_json(f"{product_url}.json")
    raw = data.get("product")
    return _normalize(base_url, raw) if raw else None


def _normalize(base_url: str, raw: dict) -> NormalizedProduct:
    variants = [
        NormalizedVariant(
            external_id=str(v["id"]),
            price=Decimal(str(v["price"])),
            compare_at_price=(
                Decimal(str(v["compare_at_price"])) if v.get("compare_at_price") else None
            ),
            in_stock=v.get("available", True),
            size=v.get("option1"),
            color=v.get("option2"),
        )
        for v in raw.get("variants", [])
    ]
    return NormalizedProduct(
        external_id=str(raw["id"]),
        source_url=f"{base_url}/products/{raw['handle']}",
        title=raw.get("title", ""),
        description=raw.get("body_html"),
        category=raw.get("product_type") or None,
        tags=[t for t in raw.get("tags", []) if t],
        image_urls=[img["src"] for img in raw.get("images", []) if img.get("src")],
        variants=variants,
    )
