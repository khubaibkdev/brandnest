from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.services import search as search_service

router = APIRouter(tags=["search"])


class SearchHit(BaseModel):
    product_id: int
    title: str
    brand_slug: str
    brand_name: str
    category: str
    # The brand's own shelf name, kept alongside the canonical one so a result
    # still shows the detail the shopper drilled in for.
    raw_category: str | None
    audience: str | None
    price: float
    url: str
    image: str | None


class FacetValue(BaseModel):
    value: str
    count: int


class SearchOut(BaseModel):
    hits: list[SearchHit]
    total: int
    page: int
    # What the query box turned out to mean, so the app can show the price
    # filter it lifted out of "kurta under 3000" instead of silently applying it.
    query_text: str
    max_price: float | None
    min_price: float | None
    brands: list[FacetValue]
    categories: list[FacetValue]
    audiences: list[FacetValue]
    # The brands' own category names inside the current result set — the
    # drill-down under `categories`, never a flat list of all 423.
    raw_categories: list[FacetValue]


@router.get("/search", response_model=SearchOut)
def search_products(
    q: str = "",
    brand: list[str] = Query(default=[]),
    category: list[str] = Query(default=[]),
    raw_category: list[str] = Query(default=[]),
    audience: list[str] = Query(default=[]),
    min_price: float | None = None,
    max_price: float | None = None,
    include_sold_out: bool = False,
    page: int = 1,
    page_size: int = 20,
) -> SearchOut:
    parsed = search_service.parse_query(q)
    filters = search_service.SearchFilters(
        brand_slugs=brand,
        categories=category,
        raw_categories=raw_category,
        audiences=audience,
        min_price=min_price,
        max_price=max_price,
        in_stock_only=not include_sold_out,
    )
    try:
        result = search_service.search(parsed, filters, page=page, page_size=page_size)
    except Exception as error:  # noqa: BLE001 - any Meilisearch failure reads the same
        # Search is the only thing that needs Meilisearch. Saying so plainly
        # beats a 500 that looks like the whole API is down.
        raise HTTPException(
            status_code=503, detail="Search is unavailable right now"
        ) from error

    facets = result.get("facetDistribution") or {}
    return SearchOut(
        hits=[_to_hit(hit) for hit in result["hits"]],
        total=_total(result, facets),
        page=page,
        query_text=parsed.text,
        max_price=parsed.max_price if parsed.max_price is not None else max_price,
        min_price=parsed.min_price if parsed.min_price is not None else min_price,
        brands=_to_facet(facets.get("brand_slug")),
        categories=_to_facet(facets.get("category")),
        audiences=_to_facet(facets.get("audience")),
        raw_categories=_to_facet(facets.get("raw_category")),
    )


def _total(result: dict, facets: dict) -> int:
    """`estimatedTotalHits` stops at Meilisearch's 1,000-hit pagination cap, so
    a search matching 2,290 products reports 1,000 — a number the shopper would
    read as the truth. The category facet is counted over the whole filtered
    set, and every document has a category, so its sum is the real total.
    """
    by_category = facets.get("category")
    if by_category:
        return sum(by_category.values())
    return result.get("estimatedTotalHits", len(result["hits"]))


def _to_hit(hit: dict) -> SearchHit:
    return SearchHit(
        product_id=hit["id"],
        title=hit["title"],
        brand_slug=hit["brand_slug"],
        brand_name=hit["brand_name"],
        category=hit["category"],
        raw_category=hit.get("raw_category"),
        audience=hit.get("audience"),
        price=hit["price"],
        url=hit["url"],
        image=hit.get("image"),
    )


def _to_facet(distribution: dict | None) -> list[FacetValue]:
    """Biggest first — a filter list is read top-down, and the values worth
    picking are the ones with results behind them."""
    return [
        FacetValue(value=value, count=count)
        for value, count in sorted(
            (distribution or {}).items(), key=lambda item: -item[1]
        )
    ]
