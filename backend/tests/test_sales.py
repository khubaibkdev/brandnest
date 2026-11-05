from datetime import date, datetime, timedelta, timezone

import pytest

from app.models import Brand, SaleEvent
from app.services import deals

NOW = datetime.now(timezone.utc)


@pytest.fixture
def brand(session):
    brand = Brand(slug="cal-brand", name="Cal Brand", website_url="https://example.pk")
    session.add(brand)
    session.flush()
    return brand


def make_sale(session, brand, **overrides):
    fields = {
        "title": "Summer Sale",
        "status": deals.LIVE,
        "starts_at": NOW - timedelta(days=1),
        "ends_at": NOW + timedelta(days=6),
        **overrides,
    }
    sale = SaleEvent(brand_id=brand.id, **fields)
    session.add(sale)
    session.flush()
    return sale


def sale_ids(client, params=""):
    response = client.get(f"/sales{params}")
    assert response.status_code == 200
    return [sale["id"] for sale in response.json()]


@pytest.mark.parametrize("status", [deals.VERIFIED, deals.LIVE, deals.EXPIRED])
def test_the_calendar_keeps_what_the_desk_approved(session, client, brand, status):
    """Including events that have ended — the app drops the badge, not the row."""
    sale = make_sale(session, brand, status=status)

    assert sale.id in sale_ids(client)


@pytest.mark.parametrize(
    "status", [deals.DRAFT, deals.NEEDS_VERIFICATION, deals.REJECTED, deals.CORRECTED]
)
def test_nothing_unapproved_reaches_the_calendar(session, client, brand, status):
    sale = make_sale(session, brand, status=status)

    assert sale.id not in sale_ids(client)


def test_a_sale_with_no_dates_is_simply_on(session, client, brand):
    sale = make_sale(session, brand, starts_at=None, ends_at=None)

    assert sale.id in sale_ids(client)


def test_events_outside_the_window_are_left_out(session, client, brand):
    long_gone = make_sale(
        session, brand,
        status=deals.EXPIRED,
        starts_at=NOW - timedelta(days=400), ends_at=NOW - timedelta(days=380),
    )
    far_off = make_sale(
        session, brand,
        status=deals.VERIFIED,
        starts_at=NOW + timedelta(days=200), ends_at=NOW + timedelta(days=210),
    )
    current = make_sale(session, brand)

    ids = sale_ids(client)

    assert current.id in ids
    assert long_gone.id not in ids
    assert far_off.id not in ids


def test_the_window_can_be_asked_for_explicitly(session, client, brand):
    last_year = make_sale(
        session, brand,
        status=deals.EXPIRED,
        starts_at=NOW - timedelta(days=400), ends_at=NOW - timedelta(days=380),
    )
    asked_from = (date.today() - timedelta(days=420)).isoformat()
    asked_to = (date.today() - timedelta(days=370)).isoformat()

    assert last_year.id in sale_ids(client, f"?from={asked_from}&to={asked_to}")


def test_the_soonest_sale_comes_first(session, client, brand):
    later = make_sale(session, brand, starts_at=NOW + timedelta(days=10))
    sooner = make_sale(session, brand, starts_at=NOW + timedelta(days=2))
    undated = make_sale(session, brand, starts_at=None)

    mine = {later.id, sooner.id, undated.id}
    assert [id for id in sale_ids(client) if id in mine] == [
        undated.id,
        sooner.id,
        later.id,
    ]


def test_the_brand_travels_with_the_event(session, client, brand):
    make_sale(session, brand)

    sale = next(s for s in client.get("/sales").json() if s["brand_slug"] == "cal-brand")

    assert sale["brand_name"] == "Cal Brand"
