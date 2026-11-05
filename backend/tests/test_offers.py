from datetime import date, timedelta

import pytest

from app.models import Bank, BankOffer, Brand

TODAY = date.today()


@pytest.fixture
def brand(session):
    brand = Brand(slug="test-brand", name="Test Brand", website_url="https://example.pk")
    session.add(brand)
    session.flush()
    return brand


@pytest.fixture
def bank(session):
    bank = Bank(slug="test-bank", name="Test Bank")
    session.add(bank)
    session.flush()
    return bank


def make_offer(session, bank, brand_id, **overrides):
    fields = {
        "card_types": ["credit"],
        "discount_pct": 10,
        "channel": "online",
        "status": "live",
        "valid_from": TODAY - timedelta(days=1),
        "valid_to": TODAY + timedelta(days=1),
        **overrides,
    }
    offer = BankOffer(bank_id=bank.id, brand_id=brand_id, **fields)
    session.add(offer)
    session.flush()
    return offer


def offer_ids(client, slug="test-brand"):
    response = client.get(f"/brands/{slug}/offers")
    assert response.status_code == 200
    return [offer["id"] for offer in response.json()]


def test_shows_this_brands_offers_and_multi_brand_offers(session, client, bank, brand):
    mine = make_offer(session, bank, brand.id)
    everyones = make_offer(session, bank, None)
    other_brand = Brand(slug="other", name="Other", website_url="https://other.pk")
    session.add(other_brand)
    session.flush()
    theirs = make_offer(session, bank, other_brand.id)

    ids = offer_ids(client)

    assert mine.id in ids
    assert everyones.id in ids
    assert theirs.id not in ids


@pytest.mark.parametrize("status", ["verified", "live"])
def test_shows_desk_approved_offers(session, client, bank, brand, status):
    offer = make_offer(session, bank, brand.id, status=status)

    assert offer.id in offer_ids(client)


@pytest.mark.parametrize("status", ["draft", "needs_verification", "rejected", "expired"])
def test_hides_offers_no_human_has_approved(session, client, bank, brand, status):
    offer = make_offer(session, bank, brand.id, status=status)

    assert offer.id not in offer_ids(client)


def test_hides_offers_outside_their_validity_window(session, client, bank, brand):
    """The status job may not have run; the dates decide either way."""
    finished = make_offer(
        session, bank, brand.id,
        valid_from=TODAY - timedelta(days=30), valid_to=TODAY - timedelta(days=1),
    )
    not_started = make_offer(
        session, bank, brand.id,
        valid_from=TODAY + timedelta(days=1), valid_to=TODAY + timedelta(days=30),
    )
    open_ended = make_offer(session, bank, brand.id, valid_from=None, valid_to=None)

    ids = offer_ids(client)

    assert finished.id not in ids
    assert not_started.id not in ids
    assert open_ended.id in ids


def test_best_saving_comes_first(session, client, bank, brand):
    small = make_offer(session, bank, brand.id, discount_pct=5)
    big = make_offer(session, bank, brand.id, discount_pct=25)
    unquantified = make_offer(session, bank, brand.id, discount_pct=None)

    # Seeded multi-brand offers answer for every brand, so compare only our own.
    mine = {small.id, big.id, unquantified.id}
    assert [id for id in offer_ids(client) if id in mine] == [
        big.id,
        small.id,
        unquantified.id,
    ]


def test_unknown_brand_is_a_404(client):
    assert client.get("/brands/nope/offers").status_code == 404


def test_brand_offers_name_the_bank_the_app_can_filter_on(session, client, bank, brand):
    """The directory saves "my cards" against the slug, not the display name."""
    mine = make_offer(session, bank, brand.id)

    served = client.get("/brands/test-brand/offers").json()

    # Seeded multi-brand offers answer for every brand, so find our own row.
    assert next(o for o in served if o["id"] == mine.id)["bank_slug"] == "test-bank"


# --- the cross-brand directory (US-5) ---


def directory(client) -> list[dict]:
    response = client.get("/offers")
    assert response.status_code == 200
    return response.json()


def directory_by_id(client) -> dict[int, dict]:
    return {offer["id"]: offer for offer in directory(client)}


def test_directory_carries_every_brands_offers(session, client, bank, brand):
    other_brand = Brand(slug="other", name="Other", website_url="https://other.pk")
    session.add(other_brand)
    session.flush()
    mine = make_offer(session, bank, brand.id)
    theirs = make_offer(session, bank, other_brand.id)

    served = directory_by_id(client)

    assert served[mine.id]["brand_name"] == "Test Brand"
    assert served[theirs.id]["brand_name"] == "Other"


def test_a_multi_brand_offer_names_no_brand(session, client, bank):
    """Null brand is what the app renders as "All brands"."""
    everyones = make_offer(session, bank, None)

    served = directory_by_id(client)[everyones.id]

    assert served["brand_slug"] is None
    assert served["brand_name"] is None


@pytest.mark.parametrize("status", ["draft", "needs_verification", "rejected", "expired"])
def test_directory_hides_offers_no_human_has_approved(session, client, bank, brand, status):
    offer = make_offer(session, bank, brand.id, status=status)

    assert offer.id not in directory_by_id(client)


def test_directory_hides_expired_offers(session, client, bank, brand):
    """US-5's "expired offers auto-hidden", enforced by the dates themselves."""
    finished = make_offer(
        session, bank, brand.id,
        valid_from=TODAY - timedelta(days=30), valid_to=TODAY - timedelta(days=1),
    )
    not_started = make_offer(
        session, bank, brand.id,
        valid_from=TODAY + timedelta(days=1), valid_to=TODAY + timedelta(days=30),
    )
    open_ended = make_offer(session, bank, brand.id, valid_from=None, valid_to=None)

    served = directory_by_id(client)

    assert finished.id not in served
    assert not_started.id not in served
    assert open_ended.id in served


def test_directory_groups_by_bank_best_saving_first(session, client, brand):
    zebra = Bank(slug="zebra-bank", name="Zebra Bank")
    apple = Bank(slug="apple-bank", name="Apple Bank")
    session.add_all([zebra, apple])
    session.flush()
    zebra_small = make_offer(session, zebra, brand.id, discount_pct=5)
    zebra_big = make_offer(session, zebra, brand.id, discount_pct=25)
    apple_only = make_offer(session, apple, brand.id, discount_pct=10)

    # Seeded offers answer here too, so compare only the rows this test made.
    mine = {zebra_small.id, zebra_big.id, apple_only.id}
    served = [offer["id"] for offer in directory(client) if offer["id"] in mine]

    assert served == [apple_only.id, zebra_big.id, zebra_small.id]
