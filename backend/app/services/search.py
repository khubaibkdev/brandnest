"""US-11: reading what a shopper typed, and asking Meilisearch for it.

The AC's own example is "kurta under 3000" — one box, holding both the thing
and its price. So the price phrase is lifted out of the query here rather than
being left for the shopper to re-enter into a slider they did not ask for.
"""

import re
from dataclasses import dataclass, field

import meilisearch

from app.services.search_index import INDEX_NAME, client

MAX_PAGE_SIZE = 50

# "under 3000", "below Rs 3000", "3000 se kam", "upto 3k". Written as one
# alternation per direction so the number can sit on either side of the words,
# which is where Roman-Urdu puts it ("3000 se kam" = "less than 3000").
_CEILING = re.compile(
    r"\b(?:under|below|less\s+than|upto|up\s+to|max)\s*(?:rs\.?|pkr)?\s*(\d[\d,]*)\s*(k?)\b"
    r"|\b(?:rs\.?|pkr)?\s*(\d[\d,]*)\s*(k?)\s*(?:se\s+kam|ya\s+kam|or\s+less)\b",
    re.IGNORECASE,
)
_FLOOR = re.compile(
    r"\b(?:over|above|more\s+than|min|at\s+least)\s*(?:rs\.?|pkr)?\s*(\d[\d,]*)\s*(k?)\b"
    r"|\b(?:rs\.?|pkr)?\s*(\d[\d,]*)\s*(k?)\s*(?:se\s+zyada|se\s+ziada|or\s+more)\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ParsedQuery:
    """What the shopper typed, split into words to match and prices to filter."""

    text: str
    max_price: float | None = None
    min_price: float | None = None


@dataclass(frozen=True)
class SearchFilters:
    brand_slugs: list[str] = field(default_factory=list)
    categories: list[str] = field(default_factory=list)
    raw_categories: list[str] = field(default_factory=list)
    audiences: list[str] = field(default_factory=list)
    min_price: float | None = None
    max_price: float | None = None
    in_stock_only: bool = True


def parse_query(raw: str) -> ParsedQuery:
    """Lift any price phrase out of the query, leaving the words to search on.

    The phrase is removed, not merely read: leaving "under 3000" in the text
    makes Meilisearch look for products whose *titles* say "under", and pushes
    the ones that actually match down the ranking.
    """
    text = raw
    max_price, text = _take_price(_CEILING, text)
    min_price, text = _take_price(_FLOOR, text)
    return ParsedQuery(
        text=re.sub(r"\s+", " ", text).strip(),
        max_price=max_price,
        min_price=min_price,
    )


def search(
    query: ParsedQuery,
    filters: SearchFilters,
    page: int = 1,
    page_size: int = 20,
    search_client: meilisearch.Client | None = None,
) -> dict:
    index = (search_client or client()).index(INDEX_NAME)
    return index.search(
        query.text,
        {
            "filter": build_filter(query, filters),
            "limit": min(page_size, MAX_PAGE_SIZE),
            "offset": (max(page, 1) - 1) * min(page_size, MAX_PAGE_SIZE),
            # Counts for every facet value, so the filter sheet can show what
            # narrowing by each one would actually leave. `raw_category` is in
            # here for the drill-down: once a canonical category is picked, the
            # brand's own shelf names under it are what remains worth choosing.
            "facets": ["brand_slug", "category", "audience", "raw_category"],
        },
    )


def build_filter(query: ParsedQuery, filters: SearchFilters) -> list[str]:
    """Meilisearch's filter grammar: a list is ANDed, an inner list is ORed.

    A price typed into the query wins over the same bound from the filter
    sheet — the shopper wrote it more recently than they set the slider.
    """
    clauses: list[str | list[str]] = []
    if filters.in_stock_only:
        clauses.append("is_available = true")
    for attribute, values in (
        ("brand_slug", filters.brand_slugs),
        ("category", filters.categories),
        ("raw_category", filters.raw_categories),
        ("audience", filters.audiences),
    ):
        if values:
            clauses.append([f'{attribute} = "{_escape(value)}"' for value in values])

    ceiling = query.max_price if query.max_price is not None else filters.max_price
    floor = query.min_price if query.min_price is not None else filters.min_price
    if ceiling is not None:
        clauses.append(f"price <= {ceiling}")
    if floor is not None:
        clauses.append(f"price >= {floor}")
    return clauses


def _take_price(pattern: re.Pattern[str], text: str) -> tuple[float | None, str]:
    match = pattern.search(text)
    if match is None:
        return None, text
    digits, thousands = (match.group(1), match.group(2)) if match.group(1) else (
        match.group(3),
        match.group(4),
    )
    amount = float(digits.replace(",", "")) * (1000 if thousands else 1)
    return amount, text[: match.start()] + " " + text[match.end() :]


def _escape(value: str) -> str:
    return value.replace('"', '\\"')
