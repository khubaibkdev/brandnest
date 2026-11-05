from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.auth import current_user
from app.db import db_session
from app.models import Bank, DeviceToken, User

router = APIRouter(tags=["me"], prefix="/me")


class DeviceTokenIn(BaseModel):
    fcm_token: str
    platform: str = "android"


@router.put("/device-token", status_code=204)
def register_device_token(
    payload: DeviceTokenIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> None:
    """Direct-to-device push (US-13) needs somewhere to look up a shopper's
    token. `fcm_token` is unique regardless of who sends it, so re-registering
    on a linked/switched account moves the row to the new owner rather than
    failing on the old one."""
    session.execute(
        insert(DeviceToken)
        .values(user_id=user.id, fcm_token=payload.fcm_token, platform=payload.platform)
        .on_conflict_do_update(
            index_elements=["fcm_token"],
            set_={"user_id": user.id, "platform": payload.platform},
        )
    )
    session.commit()


class SavedCard(BaseModel):
    """A card the shopper carries, as the app speaks it.

    Slugs on the wire, bank ids in the column: the slug is the identity the app
    already knows from `/offers`, and the id is what `user.my_banks` was designed
    to hold (ARCHITECTURE.md §5).
    """

    bank_slug: str
    card_type: str


@router.get("/banks", response_model=list[SavedCard])
def list_my_banks(
    user: User = Depends(current_user), session: Session = Depends(db_session)
) -> list[SavedCard]:
    """The cards this account has saved, across every device it signs in on."""
    return _to_cards(session, user.my_banks)


@router.put("/banks", response_model=list[SavedCard])
def replace_my_banks(
    cards: list[SavedCard],
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> list[SavedCard]:
    """Replace the saved set outright — it is a list of ticks, not a log.

    Merging device-local cards into the account is the app's job at sign-in;
    by the time it calls this, it has already decided what the set should be.
    """
    slugs = {slug for slug, in session.execute(select(Bank.slug))}
    unknown = sorted({card.bank_slug for card in cards} - slugs)
    if unknown:
        raise HTTPException(status_code=400, detail=f"Unknown bank: {', '.join(unknown)}")

    ids_by_slug = dict(session.execute(select(Bank.slug, Bank.id)).all())
    # dict-of-none rather than a set: ticking the same card twice is not an
    # error, but it should not be stored twice either, and order is worth keeping.
    unique = dict.fromkeys((card.bank_slug, card.card_type) for card in cards)
    user.my_banks = [
        {"bank_id": ids_by_slug[slug], "card_type": card_type}
        for slug, card_type in unique
    ]
    # JSONB reassignment is a new list object, but say so explicitly rather than
    # rely on the ORM noticing.
    flag_modified(user, "my_banks")
    session.commit()
    return _to_cards(session, user.my_banks)


def _to_cards(session: Session, my_banks: list) -> list[SavedCard]:
    if not my_banks:
        return []
    slugs_by_id = dict(session.execute(select(Bank.id, Bank.slug)).all())
    return [
        SavedCard(bank_slug=slugs_by_id[saved["bank_id"]], card_type=saved["card_type"])
        for saved in my_banks
        # A bank dropped from the table should not break a shopper's whole list.
        if saved["bank_id"] in slugs_by_id
    ]
