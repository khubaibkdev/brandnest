"""US-18: points for a completed order — detection, the pending hold, and the
promotion to confirmed."""

from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.auth import get_or_create_user
from app.models import Brand, BrandConfig, PointsLedger
from app.services import orders, points

THANK_YOU = "https://outfitters.com.pk/checkouts/c/abc123def456/thank_you"


@pytest.fixture
def brand(session):
    brand = Brand(
        slug="test-orders-brand",
        name="Test Orders Brand",
        website_url="https://outfitters.com.pk",
        platform="shopify",
        is_active=True,
        categories=["women"],
    )
    session.add(brand)
    session.flush()
    session.add(
        BrandConfig(
            brand_id=brand.id,
            order_confirm_patterns=[r"/thank[_-]you", r"/orders/[0-9a-f]{32}"],
        )
    )
    session.flush()
    return brand


def test_a_thank_you_page_awards_pending_points(session, brand):
    user = get_or_create_user(session, "uid-order-1")

    awarded, amount = orders.record_order(session, user.id, brand, THANK_YOU)

    assert awarded is True
    assert amount == orders.ORDER_POINTS
    row = session.scalar(select(PointsLedger).where(PointsLedger.user_id == user.id))
    assert row.reason == "order_confirmed"
    assert row.status == "pending"


def test_pending_points_are_visible_but_not_spendable(session, brand):
    """The whole point of the hold: a shopper sees the reward coming without
    the balance claiming it is already theirs."""
    user = get_or_create_user(session, "uid-order-2")

    orders.record_order(session, user.id, brand, THANK_YOU)

    assert points.balance(session, user.id) == 0
    assert points.pending_balance(session, user.id) == orders.ORDER_POINTS


def test_reopening_the_confirmation_page_does_not_pay_twice(session, brand):
    """A thank-you page is bookmarkable and survives a back button."""
    user = get_or_create_user(session, "uid-order-3")
    orders.record_order(session, user.id, brand, THANK_YOU)

    awarded, _ = orders.record_order(session, user.id, brand, THANK_YOU)

    assert awarded is False
    assert points.pending_balance(session, user.id) == orders.ORDER_POINTS


def test_a_page_that_is_not_a_confirmation_is_refused(session, brand):
    """The client's copy of the patterns comes from a public endpoint, so the
    reward cannot depend on the client having applied them honestly."""
    user = get_or_create_user(session, "uid-order-4")

    with pytest.raises(orders.NotAnOrderPage):
        orders.record_order(
            session, user.id, brand, "https://outfitters.com.pk/collections/sale"
        )

    assert points.pending_balance(session, user.id) == 0


def test_another_brands_confirmation_url_does_not_pay(session, brand):
    """Patterns are per brand; a URL is only an order for the brand that
    claims it."""
    user = get_or_create_user(session, "uid-order-5")
    other = Brand(
        slug="test-orders-other",
        name="Other",
        website_url="https://example.com",
        platform="shopify",
        is_active=True,
        categories=["women"],
    )
    session.add(other)
    session.flush()
    session.add(BrandConfig(brand_id=other.id, order_confirm_patterns=[]))
    session.flush()

    with pytest.raises(orders.NotAnOrderPage):
        orders.record_order(session, user.id, other, THANK_YOU)


def test_a_malformed_pattern_does_not_block_the_others(session, brand):
    """A desk typo in one pattern must not cost every shopper their points."""
    config = session.get(BrandConfig, brand.id)
    config.order_confirm_patterns = ["[unclosed", r"/thank[_-]you"]
    session.flush()
    user = get_or_create_user(session, "uid-order-6")

    awarded, _ = orders.record_order(session, user.id, brand, THANK_YOU)

    assert awarded is True


def test_the_hold_must_elapse_before_points_confirm(session, brand):
    user = get_or_create_user(session, "uid-order-7")
    orders.record_order(session, user.id, brand, THANK_YOU)

    assert orders.confirm_due_orders(session) == 0
    assert points.balance(session, user.id) == 0


def test_points_confirm_once_the_return_window_has_passed(session, brand):
    user = get_or_create_user(session, "uid-order-8")
    orders.record_order(session, user.id, brand, THANK_YOU)
    later = datetime.now(timezone.utc) + timedelta(days=orders.HOLD_DAYS, minutes=1)

    assert orders.confirm_due_orders(session, now=later) == 1
    assert points.balance(session, user.id) == orders.ORDER_POINTS
    assert points.pending_balance(session, user.id) == 0


def test_confirming_is_not_repeated_on_the_next_run(session, brand):
    user = get_or_create_user(session, "uid-order-9")
    orders.record_order(session, user.id, brand, THANK_YOU)
    later = datetime.now(timezone.utc) + timedelta(days=orders.HOLD_DAYS, minutes=1)
    orders.confirm_due_orders(session, now=later)

    assert orders.confirm_due_orders(session, now=later) == 0
    assert points.balance(session, user.id) == orders.ORDER_POINTS


def test_the_endpoint_rejects_a_url_that_is_not_a_confirmation(client, as_signed_in, brand):
    as_signed_in("uid-order-api")

    response = client.post(
        "/me/points/order",
        json={"brand_slug": brand.slug, "url": "https://outfitters.com.pk/products/x"},
    )

    assert response.status_code == 400


def test_the_endpoint_awards_and_reports_pending(client, as_signed_in, brand):
    as_signed_in("uid-order-api-2")

    response = client.post(
        "/me/points/order", json={"brand_slug": brand.slug, "url": THANK_YOU}
    )

    body = response.json()
    assert body["awarded"] is True
    assert body["pending"] == orders.ORDER_POINTS
    assert body["balance"] == 0


def test_an_unknown_brand_is_a_404(client, as_signed_in):
    as_signed_in("uid-order-api-3")

    response = client.post(
        "/me/points/order", json={"brand_slug": "no-such-brand", "url": THANK_YOU}
    )

    assert response.status_code == 404
