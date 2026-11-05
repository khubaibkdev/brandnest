from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.db import db_session
from app.models import Bank, BankOffer, Brand
from app.services import deals

router = APIRouter(tags=["offers"])


class BankOfferOut(BaseModel):
    id: int
    bank_slug: str
    bank_name: str
    card_types: list[str]
    # Money and percentages are display values here — the app formats them and
    # never computes with them, so float keeps the JSON a number.
    discount_pct: float | None
    max_discount_amt: float | None
    min_spend: float | None
    channel: str
    valid_from: date | None
    valid_to: date | None
    proof_url: str | None


class DirectoryOfferOut(BankOfferOut):
    """An offer in the cross-brand directory, where the brand is not implied.

    Both brand fields are null for a multi-brand offer — one that works at every
    brand we carry.
    """

    brand_slug: str | None
    brand_name: str | None


def _visible_today(today: date) -> list:
    """What makes an offer shopper-visible, in one place.

    Both routes reuse this, so the directory and the toolbar chips cannot come to
    disagree about which offers exist. The validity window is enforced here as
    well as by the status machine, so an offer never shows a day early or a day
    late even if the hourly transition job has not run yet — which is also where
    US-5's "expired offers auto-hidden" comes from.
    """
    return [
        BankOffer.status.in_(deals.PUBLISHED),
        or_(BankOffer.valid_from.is_(None), BankOffer.valid_from <= today),
        or_(BankOffer.valid_to.is_(None), BankOffer.valid_to >= today),
    ]


@router.get("/brands/{slug}/offers", response_model=list[BankOfferOut])
def list_brand_offers(
    slug: str, session: Session = Depends(db_session)
) -> list[BankOfferOut]:
    """Bank offers a shopper can use on this brand right now.

    Includes multi-brand offers (`brand_id IS NULL`).
    """
    brand_id = session.scalar(select(Brand.id).where(Brand.slug == slug))
    if brand_id is None:
        raise HTTPException(status_code=404, detail="Unknown brand")

    stmt = (
        select(BankOffer, Bank)
        .join(Bank, Bank.id == BankOffer.bank_id)
        .where(
            *_visible_today(date.today()),
            or_(BankOffer.brand_id == brand_id, BankOffer.brand_id.is_(None)),
        )
        # Best saving first: that is the one worth a shopper's attention.
        .order_by(BankOffer.discount_pct.desc().nullslast(), Bank.name)
    )
    return [
        BankOfferOut(**_shared_fields(offer, bank))
        for offer, bank in session.execute(stmt)
    ]


@router.get("/offers", response_model=list[DirectoryOfferOut])
def list_offers(session: Session = Depends(db_session)) -> list[DirectoryOfferOut]:
    """Every bank offer a shopper can use today, across every brand.

    Served unfiltered because the directory filters by the shopper's own banks
    and card types on the device: the whole set is small, and a directory that
    reads offline is worth more than one that can filter server-side.

    Ordered by bank, best saving first within each — the directory groups by bank,
    so this is the order it renders in.
    """
    stmt = (
        select(BankOffer, Bank, Brand)
        .join(Bank, Bank.id == BankOffer.bank_id)
        # Outer: a multi-brand offer has no brand row and still belongs here.
        .outerjoin(Brand, Brand.id == BankOffer.brand_id)
        .where(*_visible_today(date.today()))
        .order_by(Bank.name, BankOffer.discount_pct.desc().nullslast(), BankOffer.id)
    )
    return [
        DirectoryOfferOut(
            **_shared_fields(offer, bank),
            brand_slug=brand.slug if brand else None,
            brand_name=brand.name if brand else None,
        )
        for offer, bank, brand in session.execute(stmt)
    ]


def _shared_fields(offer: BankOffer, bank: Bank) -> dict:
    return {
        "id": offer.id,
        "bank_slug": bank.slug,
        "bank_name": bank.name,
        "card_types": offer.card_types,
        "discount_pct": offer.discount_pct,
        "max_discount_amt": offer.max_discount_amt,
        "min_spend": offer.min_spend,
        "channel": offer.channel,
        "valid_from": offer.valid_from,
        "valid_to": offer.valid_to,
        "proof_url": offer.proof_url,
    }
