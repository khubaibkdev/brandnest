"""US-11: reading the query box, and the filter it becomes."""

import pytest

from app.services import search as search_service
from app.services.search import ParsedQuery, SearchFilters, build_filter, parse_query


@pytest.mark.parametrize(
    "raw,text,ceiling",
    [
        # The AC's own example.
        ("kurta under 3000", "kurta", 3000),
        ("kurta below Rs 3000", "kurta", 3000),
        ("kurta less than 3,000", "kurta", 3000),
        ("lawn upto 5k", "lawn", 5000),
        # Roman-Urdu puts the number first: "3000 se kam" is "under 3000".
        ("3000 se kam lawn", "lawn", 3000),
        ("lawn 2500 ya kam", "lawn", 2500),
        # A price with no words is still a price.
        ("under 1500", "", 1500),
    ],
)
def test_lifts_a_price_ceiling_out_of_the_query(raw, text, ceiling):
    parsed = parse_query(raw)

    assert parsed.text == text
    assert parsed.max_price == ceiling


@pytest.mark.parametrize(
    "raw,text,floor",
    [
        ("kurta above 3000", "kurta", 3000),
        ("kurta over Rs 2,500", "kurta", 2500),
        ("lawn 4000 se zyada", "lawn", 4000),
    ],
)
def test_lifts_a_price_floor_out_of_the_query(raw, text, floor):
    parsed = parse_query(raw)

    assert parsed.text == text
    assert parsed.min_price == floor


def test_a_query_with_no_price_is_left_alone():
    parsed = parse_query("khaadi lawn 3 piece")

    assert parsed.text == "khaadi lawn 3 piece"
    assert parsed.max_price is None
    assert parsed.min_price is None


def test_a_price_range_can_come_from_both_ends():
    parsed = parse_query("kurta over 2000 under 5000")

    assert parsed.text == "kurta"
    assert (parsed.min_price, parsed.max_price) == (2000, 5000)


def test_the_price_words_are_removed_not_just_read():
    """Leaving "under" in the text makes Meilisearch hunt for products whose
    titles say "under", pushing the real matches down the ranking."""
    assert "under" not in parse_query("kurta under 3000").text


def test_filters_ask_for_in_stock_products_by_default():
    assert "is_available = true" in build_filter(ParsedQuery("kurta"), SearchFilters())


def test_sold_out_products_can_be_asked_for():
    clauses = build_filter(ParsedQuery("kurta"), SearchFilters(in_stock_only=False))

    assert "is_available = true" not in clauses


def test_several_values_of_one_facet_are_an_or():
    clauses = build_filter(
        ParsedQuery("kurta"), SearchFilters(brand_slugs=["zellbury", "edenrobe"])
    )

    assert ['brand_slug = "zellbury"', 'brand_slug = "edenrobe"'] in clauses


def test_the_brand_and_the_canonical_and_raw_categories_all_filter():
    clauses = build_filter(
        ParsedQuery("kurta"),
        SearchFilters(
            brand_slugs=["zellbury"],
            categories=["Kurta & Kurti"],
            raw_categories=["Essential Pret"],
            audiences=["Women"],
        ),
    )

    assert ['category = "Kurta & Kurti"'] in clauses
    assert ['raw_category = "Essential Pret"'] in clauses
    assert ['audience = "Women"'] in clauses


def test_a_price_typed_into_the_query_beats_the_filter_sheet():
    """The shopper typed it more recently than they set the slider."""
    clauses = build_filter(
        ParsedQuery("kurta", max_price=3000), SearchFilters(max_price=9000)
    )

    assert "price <= 3000" in clauses
    assert "price <= 9000" not in clauses


def test_the_filter_sheet_still_applies_when_the_query_has_no_price():
    clauses = build_filter(ParsedQuery("kurta"), SearchFilters(max_price=9000))

    assert "price <= 9000" in clauses


def test_a_quote_in_a_category_name_cannot_break_the_filter():
    clauses = build_filter(ParsedQuery(""), SearchFilters(raw_categories=['Men"s']))

    assert ['raw_category = "Men\\"s"'] in clauses


# --- the endpoint -----------------------------------------------------------


def _stub_result(**overrides) -> dict:
    return {
        "hits": [
            {
                "id": 11,
                "title": "LIGHT BROWN SEMI-FORMAL KURTA",
                "brand_slug": "junaid-jamshed",
                "brand_name": "Junaid Jamshed",
                "category": "Kurta & Kurti",
                "raw_category": "Kurta",
                "audience": "Men",
                "price": 2390.0,
                "url": "https://www.junaidjamshed.com/products/x",
                "image": None,
            }
        ],
        "estimatedTotalHits": 1000,
        "facetDistribution": {
            "brand_slug": {"zellbury": 959, "junaid-jamshed": 192},
            "category": {"Kurta & Kurti": 1091, "Ready to Wear": 273},
            "audience": {"Women": 800, "Men": 564},
        },
        **overrides,
    }


def test_search_returns_hits_facets_and_the_price_it_parsed(client, monkeypatch):
    monkeypatch.setattr(search_service, "search", lambda *a, **k: _stub_result())

    body = client.get("/search", params={"q": "kurta under 3000"}).json()

    assert body["query_text"] == "kurta"
    assert body["max_price"] == 3000
    assert body["hits"][0]["brand_name"] == "Junaid Jamshed"
    assert body["hits"][0]["raw_category"] == "Kurta"
    assert body["brands"][0] == {"value": "zellbury", "count": 959}


def test_the_reported_total_is_not_meilisearchs_1000_hit_cap(client, monkeypatch):
    """`estimatedTotalHits` saturates at 1,000; the category facet counts the
    whole filtered set, so a search matching 1,364 says so."""
    monkeypatch.setattr(search_service, "search", lambda *a, **k: _stub_result())

    assert client.get("/search", params={"q": "kurta"}).json()["total"] == 1364


def test_facet_values_come_back_biggest_first(client, monkeypatch):
    monkeypatch.setattr(search_service, "search", lambda *a, **k: _stub_result())

    categories = client.get("/search", params={"q": "kurta"}).json()["categories"]

    assert [facet["count"] for facet in categories] == [1091, 273]


def test_search_being_down_does_not_read_as_the_api_being_down(client, monkeypatch):
    def explode(*args, **kwargs):
        raise ConnectionError("meilisearch unreachable")

    monkeypatch.setattr(search_service, "search", explode)

    assert client.get("/search", params={"q": "kurta"}).status_code == 503
