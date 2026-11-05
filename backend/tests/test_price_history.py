"""US-12: the price series and the Asli Sale verdict (CRAWLER_PLAYBOOK §3)."""

from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

import pytest

from app.models import Brand, PriceHistory, Product, ProductVariant
from app.services import price_history

TODAY = date(2026, 8, 31)


def _at(days_ago: int) -> datetime:
    """An observation timestamp `days_ago` before TODAY."""
    return datetime.combine(
        TODAY - timedelta(days=days_ago), datetime.min.time(), tzinfo=timezone.utc
    )


def _rows(*changes: tuple[int, str]) -> dict[int, list[tuple[datetime, Decimal]]]:
    """One variant's (days_ago, price) changes, in the shape the report takes."""
    return {1: [(_at(days_ago), Decimal(price)) for days_ago, price in changes]}


def test_no_history_has_no_verdict_to_give():
    report = price_history.build_report({}, through=TODAY)
    assert report.verdict == price_history.NO_HISTORY
    assert report.points == []
    assert report.window_days == 0


def test_price_carries_forward_across_days_with_no_change():
    report = price_history.build_report(_rows((4, "4000")), through=TODAY)

    assert [point.on for point in report.points] == [
        TODAY - timedelta(days=n) for n in reversed(range(5))
    ]
    assert {point.price for point in report.points} == {Decimal("4000")}
    assert report.window_days == 5


def test_a_price_that_never_moved_is_not_a_discount():
    report = price_history.build_report(_rows((60, "4000")), through=TODAY)

    assert report.verdict == price_history.NOT_LOWEST
    assert report.current_price == report.typical_price == Decimal("4000")


def test_a_real_drop_below_the_usual_price_is_a_genuine_sale():
    report = price_history.build_report(
        _rows((60, "4000"), (2, "3000")), through=TODAY
    )

    assert report.verdict == price_history.GENUINE
    assert report.current_price == Decimal("3000")
    assert report.typical_price == Decimal("4000")
    assert report.lowest_price == Decimal("3000")


def test_a_price_raised_then_discounted_back_is_not_a_genuine_sale():
    """The fake-discount pattern: up to 6000 inside the lookback window, then
    "off" to 3800 — still below the 4000 it really sold at, so rule 1 alone
    would have waved it through."""
    report = price_history.build_report(
        _rows((60, "4000"), (10, "6000"), (0, "3800")), through=TODAY
    )

    assert report.verdict == price_history.PRE_SALE_MARKUP
    assert report.typical_price == Decimal("4000")


def test_a_markup_older_than_the_lookback_window_does_not_taint_a_later_sale():
    report = price_history.build_report(
        _rows((80, "4000"), (60, "6000"), (0, "3800")), through=TODAY
    )

    assert report.verdict == price_history.GENUINE


def test_typical_price_is_time_weighted_not_row_counted():
    """58 days at 5000 and one day each at 4000/3000/2000. Counting rows would
    call 3500 typical and hide how long 5000 really stood."""
    report = price_history.build_report(
        _rows((60, "5000"), (2, "4000"), (1, "3000"), (0, "2000")), through=TODAY
    )

    assert report.typical_price == Decimal("5000")
    assert report.verdict == price_history.GENUINE


def test_the_series_stops_at_the_window_even_with_older_history():
    report = price_history.build_report(
        _rows((200, "4000")), through=TODAY, window_days=90
    )

    assert report.window_days == 90
    assert report.points[0].on == TODAY - timedelta(days=89)


def test_each_day_takes_the_cheapest_variant():
    report = price_history.build_report(
        {
            1: [(_at(3), Decimal("4000"))],
            2: [(_at(3), Decimal("3500"))],
        },
        through=TODAY,
    )

    assert {point.price for point in report.points} == {Decimal("3500")}


def test_a_variant_added_later_does_not_backdate_its_price():
    """A cheap size appearing today must not make last week look like a sale."""
    report = price_history.build_report(
        {
            1: [(_at(5), Decimal("4000"))],
            2: [(_at(0), Decimal("1000"))],
        },
        through=TODAY,
    )

    prices = {point.on: point.price for point in report.points}
    assert prices[TODAY - timedelta(days=3)] == Decimal("4000")
    assert prices[TODAY] == Decimal("1000")


def test_several_changes_in_one_day_keep_the_last():
    rows = {
        1: [
            (_at(1), Decimal("4000")),
            (_at(1) + timedelta(hours=6), Decimal("3600")),
        ]
    }
    report = price_history.build_report(rows, through=TODAY)

    assert {point.price for point in report.points} == {Decimal("3600")}


# --- the endpoint -----------------------------------------------------------


@pytest.fixture
def product(session):
    brand = Brand(
        slug="graph-brand",
        name="Graph Brand",
        website_url="https://example.pk",
        platform="shopify",
    )
    session.add(brand)
    session.flush()
    product = Product(
        brand_id=brand.id,
        external_id="p1",
        source_url="https://example.pk/products/a-shirt",
        title="A Shirt",
    )
    session.add(product)
    session.flush()
    variant = ProductVariant(
        product_id=product.id,
        external_id="v1",
        price=Decimal("3000"),
        in_stock=True,
        last_checked=datetime.now(timezone.utc),
    )
    session.add(variant)
    session.flush()
    now = datetime.now(timezone.utc)
    for days_ago, price in ((30, "4000"), (1, "3000")):
        session.add(
            PriceHistory(
                variant_id=variant.id,
                price=Decimal(price),
                in_stock=True,
                observed_at=now - timedelta(days=days_ago),
            )
        )
    session.commit()
    return product


def test_price_history_endpoint_returns_the_series_and_verdict(client, product):
    response = client.get(f"/products/{product.id}/price-history")

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == price_history.GENUINE
    assert body["current_price"] == 3000
    assert body["typical_price"] == 4000
    assert body["window_days"] == 31
    assert body["points"][0]["price"] == 4000
    assert body["points"][-1]["price"] == 3000


def test_price_history_endpoint_404s_on_an_unknown_product(client):
    assert client.get("/products/99999999/price-history").status_code == 404
