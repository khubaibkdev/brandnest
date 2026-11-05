"""US-13: watch-status detection and the toggle's create/delete."""

import pytest

from app.auth import get_or_create_user
from app.models import Brand, Product, WatchItem
from app.services import watches

GUEST = "firebase-uid-guest"
PRODUCT_URL = "https://example.pk/products/a-shirt"


@pytest.fixture
def brand(session):
    brand = Brand(slug="test-brand", name="Test Brand", website_url="https://example.pk")
    session.add(brand)
    session.flush()
    return brand


@pytest.fixture
def product(session, brand):
    product = Product(
        brand_id=brand.id,
        external_id="1",
        source_url=PRODUCT_URL,
        title="A Shirt",
        is_available=True,
    )
    session.add(product)
    session.flush()
    return product


@pytest.fixture
def user(session):
    return get_or_create_user(session, GUEST)


def test_a_url_matches_its_crawled_product(session, brand, product):
    found = watches.find_product_by_url(session, "test-brand", PRODUCT_URL)

    assert found is not None
    assert found.id == product.id


def test_a_url_with_query_params_still_matches(session, brand, product):
    found = watches.find_product_by_url(
        session, "test-brand", PRODUCT_URL + "?variant=123"
    )

    assert found is not None
    assert found.id == product.id


def test_a_product_from_a_different_brand_does_not_match(session, brand, product):
    other = Brand(slug="other-brand", name="Other Brand", website_url="https://other.pk")
    session.add(other)
    session.flush()

    assert watches.find_product_by_url(session, "other-brand", PRODUCT_URL) is None


def test_an_uncrawled_url_matches_nothing(session, brand):
    assert watches.find_product_by_url(session, "test-brand", PRODUCT_URL) is None


def test_watching_starts_false(session, product, user):
    assert watches.is_watching(session, user.id, product.id) is False


def test_starting_a_watch_creates_both_kinds(session, product, user):
    watches.start_watching(session, user.id, product.id)

    kinds = {
        row.kind
        for row in session.query(WatchItem).filter_by(user_id=user.id, product_id=product.id)
    }
    assert kinds == {"price_drop", "restock"}
    assert watches.is_watching(session, user.id, product.id) is True


def test_starting_the_same_watch_twice_does_not_duplicate(session, product, user):
    watches.start_watching(session, user.id, product.id)
    watches.start_watching(session, user.id, product.id)

    rows = session.query(WatchItem).filter_by(user_id=user.id, product_id=product.id).count()
    assert rows == 2  # one price_drop, one restock — not four


def test_stopping_a_watch_removes_both_kinds(session, product, user):
    watches.start_watching(session, user.id, product.id)

    watches.stop_watching(session, user.id, product.id)

    assert watches.is_watching(session, user.id, product.id) is False
    rows = session.query(WatchItem).filter_by(user_id=user.id, product_id=product.id).count()
    assert rows == 0


def test_two_shoppers_watching_the_same_product_do_not_interfere(session, product):
    first = get_or_create_user(session, "uid-one")
    second = get_or_create_user(session, "uid-two")
    watches.start_watching(session, first.id, product.id)

    assert watches.is_watching(session, second.id, product.id) is False
    watches.stop_watching(session, first.id, product.id)
    watches.start_watching(session, second.id, product.id)
    assert watches.is_watching(session, first.id, product.id) is False
    assert watches.is_watching(session, second.id, product.id) is True


class TestApi:
    def test_watch_status_for_an_unknown_url(self, client, as_signed_in, brand):
        as_signed_in()

        response = client.get(
            "/brands/test-brand/products/watch-status",
            params={"url": "https://example.pk/products/does-not-exist"},
        )

        assert response.json() == {"product_id": None, "title": None, "watching": False}

    def test_watch_status_for_a_known_product(self, client, as_signed_in, product):
        as_signed_in()

        response = client.get(
            "/brands/test-brand/products/watch-status", params={"url": PRODUCT_URL}
        )

        assert response.json() == {
            "product_id": product.id,
            "title": "A Shirt",
            "watching": False,
        }

    def test_creating_and_reading_back_a_watch(self, client, as_signed_in, product):
        as_signed_in()

        created = client.post("/me/watches", json={"product_id": product.id})
        status = client.get(
            "/brands/test-brand/products/watch-status", params={"url": PRODUCT_URL}
        )

        assert created.status_code == 204
        assert status.json()["watching"] is True

    def test_deleting_a_watch(self, client, as_signed_in, product):
        as_signed_in()
        client.post("/me/watches", json={"product_id": product.id})

        deleted = client.delete(f"/me/watches/{product.id}")
        status = client.get(
            "/brands/test-brand/products/watch-status", params={"url": PRODUCT_URL}
        )

        assert deleted.status_code == 204
        assert status.json()["watching"] is False

    def test_watching_an_unknown_product_id_is_a_404(self, client, as_signed_in):
        as_signed_in()

        response = client.post("/me/watches", json={"product_id": 999_999_999})

        assert response.status_code == 404

    def test_watch_status_requires_a_token(self, client, brand):
        response = client.get(
            "/brands/test-brand/products/watch-status", params={"url": PRODUCT_URL}
        )

        assert response.status_code == 401
