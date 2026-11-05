from datetime import date, datetime, timedelta, timezone

import pytest

from app.models import Bank, BankOffer, Brand, SaleEvent
from app.services import deals

TODAY = date.today()
NOW = datetime.now(timezone.utc)
PROOF = "https://www.sc.com/pk/promotions/"


@pytest.fixture(autouse=True)
def sent_notifications(monkeypatch):
    """Every test in this file gets a stub push sender, so `run_deal_transitions`
    never makes a real FCM call. Tests that care about what would have been sent
    ask for this fixture by name.
    """
    calls = []
    monkeypatch.setattr(
        deals,
        "send_topic_notification",
        lambda topic, title, body, data=None: calls.append(
            {"topic": topic, "title": title, "body": body, "data": data}
        ),
    )
    return calls


@pytest.fixture
def brand(session):
    brand = Brand(slug="sm-brand", name="SM Brand", website_url="https://example.pk")
    session.add(brand)
    session.flush()
    return brand


@pytest.fixture
def offer(session, brand):
    bank = Bank(slug="sm-bank", name="SM Bank")
    session.add(bank)
    session.flush()
    offer = BankOffer(bank_id=bank.id, brand_id=brand.id, status=deals.DRAFT, proof_url=PROOF)
    session.add(offer)
    session.flush()
    return offer


def test_verifying_records_who_checked_it_and_when(offer):
    deals.transition(offer, deals.VERIFIED, "founder")

    assert offer.status == deals.VERIFIED
    assert offer.verified_by == "founder"
    assert offer.verified_at is not None


def test_a_deal_without_proof_cannot_be_verified(offer):
    offer.proof_url = None

    with pytest.raises(deals.TransitionError, match="proof"):
        deals.transition(offer, deals.VERIFIED, "founder")

    assert offer.status == deals.DRAFT


def test_verification_has_to_be_signed(offer):
    with pytest.raises(deals.TransitionError, match="signed"):
        deals.transition(offer, deals.VERIFIED, actor=None)


@pytest.mark.parametrize(
    ("start", "target"),
    [
        (deals.EXPIRED, deals.VERIFIED),
        (deals.REJECTED, deals.VERIFIED),
        (deals.LIVE, deals.VERIFIED),
        (deals.DRAFT, deals.LIVE),
        (deals.DRAFT, deals.EXPIRED),
    ],
)
def test_the_machine_refuses_edges_it_does_not_have(offer, start, target):
    offer.status = start

    with pytest.raises(deals.TransitionError):
        deals.transition(offer, target, "founder")


def test_a_live_deal_can_be_corrected_and_re_verified(offer):
    offer.status = deals.LIVE

    deals.transition(offer, deals.CORRECTED, "founder")
    deals.transition(offer, deals.VERIFIED, "founder")

    assert offer.status == deals.VERIFIED


def test_rejecting_records_who_turned_it_down(offer):
    deals.transition(offer, deals.REJECTED, "founder")

    assert offer.status == deals.REJECTED
    assert offer.verified_by == "founder"


def test_the_desk_is_only_offered_moves_that_are_its_own():
    assert deals.desk_actions(deals.DRAFT) == [
        deals.NEEDS_VERIFICATION,
        deals.VERIFIED,
        deals.REJECTED,
    ]
    assert deals.desk_actions(deals.LIVE) == [deals.CORRECTED]
    assert deals.desk_actions(deals.EXPIRED) == []


def test_an_open_window_publishes_and_a_closed_one_retires(session, offer):
    offer.status = deals.VERIFIED
    offer.valid_from = TODAY - timedelta(days=1)
    offer.valid_to = TODAY + timedelta(days=7)

    deals.run_deal_transitions(session)

    assert offer.status == deals.LIVE

    offer.valid_to = TODAY - timedelta(days=1)
    deals.run_deal_transitions(session)

    assert offer.status == deals.EXPIRED


def test_a_deal_that_has_not_started_stays_out_of_sight(session, offer):
    offer.status = deals.VERIFIED
    offer.valid_from = TODAY + timedelta(days=3)
    offer.valid_to = TODAY + timedelta(days=10)

    deals.run_deal_transitions(session)

    assert offer.status == deals.VERIFIED


def test_sale_events_run_on_timestamps_not_dates(session, brand):
    sale = SaleEvent(
        brand_id=brand.id,
        title="Eid sale",
        status=deals.VERIFIED,
        starts_at=NOW - timedelta(hours=1),
        ends_at=NOW + timedelta(days=2),
    )
    session.add(sale)
    session.flush()

    deals.run_deal_transitions(session)

    assert sale.status == deals.LIVE


def test_a_sale_going_live_pushes_to_its_brand_topic(session, brand, sent_notifications):
    sale = SaleEvent(
        brand_id=brand.id,
        title="Eid sale",
        discount_text="Up to 40% off",
        status=deals.VERIFIED,
        starts_at=NOW - timedelta(hours=1),
        ends_at=NOW + timedelta(days=2),
    )
    session.add(sale)
    session.flush()

    deals.run_deal_transitions(session)

    assert sent_notifications == [
        {
            "topic": "sale-sm-brand",
            "title": "SM Brand sale is live",
            "body": "Up to 40% off",
            "data": {"type": "sale", "brand_slug": "sm-brand"},
        }
    ]


def test_a_brand_offer_going_live_pushes_to_its_bank_topic(session, offer, sent_notifications):
    offer.status = deals.VERIFIED
    offer.discount_pct = 15

    deals.run_deal_transitions(session)

    assert sent_notifications == [
        {
            "topic": "offer-sm-bank",
            "title": "SM Bank offer is live",
            "body": "15% off at SM Brand",
            "data": {"type": "offer", "bank_slug": "sm-bank"},
        }
    ]


def test_a_multi_brand_offer_going_live_says_so(session, sent_notifications):
    bank = Bank(slug="mb-bank", name="MB Bank")
    session.add(bank)
    session.flush()
    offer = BankOffer(bank_id=bank.id, brand_id=None, status=deals.VERIFIED, proof_url=PROOF)
    session.add(offer)
    session.flush()

    deals.run_deal_transitions(session)

    assert sent_notifications[0]["body"] == "New discount at all brands"


def test_nothing_still_out_of_window_pushes_anything(session, offer, sent_notifications):
    offer.status = deals.VERIFIED
    offer.valid_from = TODAY + timedelta(days=3)

    deals.run_deal_transitions(session)

    assert sent_notifications == []
