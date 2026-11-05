"""US-13: the hourly re-check that actually sends a watch alert."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest

from app.auth import get_or_create_user
from app.crawlers.base import NormalizedProduct, NormalizedVariant
from app.models import Brand, DeviceToken, Product, ProductVariant, WatchItem
from app.services import watch_alerts

GUEST = "firebase-uid-guest"


@pytest.fixture
def brand(session):
    brand = Brand(
        slug="test-brand", name="Test Brand", website_url="https://example.pk", platform="shopify"
    )
    session.add(brand)
    session.flush()
    return brand


@pytest.fixture
def product(session, brand):
    product = Product(
        brand_id=brand.id,
        external_id="1",
        source_url="https://example.pk/products/a-shirt",
        title="A Shirt",
        is_available=True,
    )
    session.add(product)
    session.flush()
    variant = ProductVariant(
        product_id=product.id,
        external_id="v1",
        price=Decimal("1000"),
        in_stock=True,
        last_checked=datetime.now(timezone.utc),
    )
    session.add(variant)
    session.flush()
    return product


@pytest.fixture
def watcher(session, product):
    user = get_or_create_user(session, GUEST)
    session.add(WatchItem(user_id=user.id, product_id=product.id, kind="price_drop"))
    session.add(WatchItem(user_id=user.id, product_id=product.id, kind="restock"))
    session.add(DeviceToken(user_id=user.id, fcm_token="fake-fcm-token"))
    session.commit()
    return user


def _stub_fetch(monkeypatch, normalized: NormalizedProduct):
    monkeypatch.setattr(watch_alerts, "_fetch_one", lambda brand, url, fetcher: normalized)


def _normalized(price: str, in_stock: bool) -> NormalizedProduct:
    return NormalizedProduct(
        external_id="1",
        source_url="https://example.pk/products/a-shirt",
        title="A Shirt",
        variants=[
            NormalizedVariant(external_id="v1", price=Decimal(price), compare_at_price=None, in_stock=in_stock)
        ],
    )


@pytest.fixture
def sent(monkeypatch):
    calls = []
    monkeypatch.setattr(
        watch_alerts,
        "send_device_notification",
        lambda token, title, body, data=None: calls.append(
            {"token": token, "title": title, "body": body, "data": data}
        )
        or True,
    )
    return calls


def test_a_price_drop_notifies_the_watcher(session, product, watcher, monkeypatch, sent):
    _stub_fetch(monkeypatch, _normalized("800", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts == {"checked": 1, "notified": 1}
    assert sent[0]["token"] == "fake-fcm-token"
    assert "Price drop" in sent[0]["title"]


def test_a_restock_notifies_the_watcher(session, product, watcher, monkeypatch, sent):
    product.variants[0].in_stock = False
    session.commit()
    _stub_fetch(monkeypatch, _normalized("1000", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts["notified"] == 1
    assert sent[0]["title"] == "Back in stock"


def test_no_change_sends_nothing(session, product, watcher, monkeypatch, sent):
    _stub_fetch(monkeypatch, _normalized("1000", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts == {"checked": 1, "notified": 0}
    assert sent == []


def test_a_price_rise_is_not_a_drop(session, product, watcher, monkeypatch, sent):
    _stub_fetch(monkeypatch, _normalized("1200", True))

    watch_alerts.run_watch_alerts(session)

    assert sent == []


def test_a_watch_already_notified_this_hour_is_not_notified_again(
    session, product, watcher, monkeypatch, sent
):
    for watch in session.query(WatchItem).filter_by(user_id=watcher.id):
        watch.last_notified_at = datetime.now(timezone.utc) - timedelta(minutes=10)
    session.commit()
    _stub_fetch(monkeypatch, _normalized("800", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts["notified"] == 0
    assert sent == []


def test_a_watch_notified_over_an_hour_ago_fires_again(session, product, watcher, monkeypatch, sent):
    for watch in session.query(WatchItem).filter_by(user_id=watcher.id):
        watch.last_notified_at = datetime.now(timezone.utc) - timedelta(hours=2)
    session.commit()
    _stub_fetch(monkeypatch, _normalized("800", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts["notified"] == 1


def test_a_watcher_with_no_device_token_is_skipped_not_crashed(session, product, monkeypatch, sent):
    user = get_or_create_user(session, "uid-no-device")
    session.add(WatchItem(user_id=user.id, product_id=product.id, kind="price_drop"))
    session.commit()
    _stub_fetch(monkeypatch, _normalized("800", True))

    counts = watch_alerts.run_watch_alerts(session)

    assert counts["notified"] == 0
    assert sent == []


def test_a_product_nobody_watches_is_never_checked(session, brand, monkeypatch, sent):
    unwatched = Product(
        brand_id=brand.id, external_id="2", source_url="https://example.pk/products/x", title="X"
    )
    session.add(unwatched)
    session.commit()

    counts = watch_alerts.run_watch_alerts(session)

    assert counts == {"checked": 0, "notified": 0}
