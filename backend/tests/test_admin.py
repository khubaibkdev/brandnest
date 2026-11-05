import pytest
from sqlalchemy import select

from app.models import Bank, BankOffer, Brand, SaleEvent
from app.services import deals

AUTH = ("founder", "brandnest")
PROOF = "https://www.meezanbank.com/card-discounts"


@pytest.fixture
def draft_offer(session):
    brand = Brand(slug="desk-brand", name="Desk Brand", website_url="https://example.pk")
    bank = Bank(slug="desk-bank", name="Desk Bank")
    session.add_all([brand, bank])
    session.flush()
    offer = BankOffer(
        bank_id=bank.id, brand_id=brand.id, status=deals.DRAFT, proof_url=PROOF
    )
    session.add(offer)
    session.flush()
    return offer


def test_the_desk_is_not_open_to_the_public(client):
    assert client.get("/admin").status_code == 401
    assert client.get("/admin/offers").status_code == 401


def test_the_queue_lists_what_is_waiting(client, draft_offer):
    response = client.get("/admin", auth=AUTH)

    assert response.status_code == 200
    assert "Desk Bank" in response.text


def test_verifying_from_the_desk_signs_it_with_the_desk_user(client, draft_offer):
    response = client.post(
        f"/admin/offers/{draft_offer.id}/status", data={"to": "verified"}, auth=AUTH
    )

    assert response.status_code == 200
    assert "verified" in response.text
    assert draft_offer.status == deals.VERIFIED
    assert draft_offer.verified_by == "founder"


def test_the_desk_cannot_skip_the_machine(client, draft_offer):
    response = client.post(
        f"/admin/offers/{draft_offer.id}/status", data={"to": "expired"}, auth=AUTH
    )

    assert response.status_code == 400
    assert draft_offer.status == deals.DRAFT


def test_going_live_is_the_workers_job_not_the_desks(client, draft_offer):
    draft_offer.status = deals.VERIFIED

    response = client.post(
        f"/admin/offers/{draft_offer.id}/status", data={"to": "live"}, auth=AUTH
    )

    assert response.status_code == 400
    assert draft_offer.status == deals.VERIFIED


def test_an_unproven_deal_is_refused_at_the_door(client, draft_offer):
    draft_offer.proof_url = None

    response = client.post(
        f"/admin/offers/{draft_offer.id}/status", data={"to": "verified"}, auth=AUTH
    )

    assert response.status_code == 400
    assert draft_offer.status == deals.DRAFT


def test_a_manually_entered_sale_starts_as_a_draft(client, session, draft_offer):
    response = client.post(
        "/admin/sales",
        data={
            "brand_id": draft_offer.brand_id,
            "title": "Azadi Sale",
            "discount_text": "Flat 30% off",
            "starts_at": "2026-08-10T00:00",
            "ends_at": "2026-08-16T23:59",
            "proof_url": PROOF,
        },
        auth=AUTH,
        follow_redirects=False,
    )

    assert response.status_code == 303
    sale = session.scalar(select(SaleEvent).where(SaleEvent.title == "Azadi Sale"))
    assert sale is not None
    # Entering a deal is not the same as vouching for it.
    assert sale.status == deals.DRAFT
    assert sale.source == "manual"
    assert sale.verified_by is None
