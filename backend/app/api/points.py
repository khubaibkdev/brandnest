from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import current_user
from app.db import db_session
from app.models import Brand, User
from app.services import orders, points

router = APIRouter(tags=["points"], prefix="/me/points")


class PointsOut(BaseModel):
    balance: int
    # Order points awaiting the end of their return window (US-18). Kept apart
    # from `balance` so the number a shopper can spend is never overstated.
    pending: int
    streak_days: int
    checked_in_today: bool
    rewarded_ads_remaining_today: int


class PointsActionOut(PointsOut):
    awarded: bool


class RewardedAdIn(BaseModel):
    # Client-generated, one per ad watched — what makes a retried request a
    # no-op instead of a second reward for the same view.
    client_ref: str


def _status(session: Session, user_id: int, today: date) -> PointsOut:
    return PointsOut(
        balance=points.balance(session, user_id),
        pending=points.pending_balance(session, user_id),
        streak_days=points.current_streak(session, user_id, today),
        checked_in_today=points.has_checked_in(session, user_id, today),
        rewarded_ads_remaining_today=max(
            0,
            points.REWARDED_AD_DAILY_CAP
            - points.rewarded_ads_watched(session, user_id, today),
        ),
    )


@router.get("", response_model=PointsOut)
def get_points(
    user: User = Depends(current_user), session: Session = Depends(db_session)
) -> PointsOut:
    return _status(session, user.id, date.today())


@router.post("/checkin", response_model=PointsActionOut)
def checkin(
    user: User = Depends(current_user), session: Session = Depends(db_session)
) -> PointsActionOut:
    today = date.today()
    awarded = points.award_points(
        session,
        user.id,
        points.CHECKIN_POINTS,
        "streak",
        idempotency_key=f"streak:{user.id}:{today.isoformat()}",
        ref_id=today.isoformat(),
    )
    return PointsActionOut(**_status(session, user.id, today).model_dump(), awarded=awarded)


@router.post("/rewarded-ad", response_model=PointsActionOut)
def rewarded_ad(
    payload: RewardedAdIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> PointsActionOut:
    today = date.today()
    under_cap = points.rewarded_ads_watched(session, user.id, today) < points.REWARDED_AD_DAILY_CAP
    awarded = under_cap and points.award_points(
        session,
        user.id,
        points.REWARDED_AD_POINTS,
        "rewarded_ad",
        idempotency_key=f"rewarded_ad:{user.id}:{payload.client_ref}",
    )
    return PointsActionOut(**_status(session, user.id, today).model_dump(), awarded=awarded)


class OrderIn(BaseModel):
    brand_slug: str
    # The confirmation page the app landed on. Re-checked against the brand's
    # own patterns server-side — this arrives from the client.
    url: str


@router.post("/order", response_model=PointsActionOut)
def record_order(
    body: OrderIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> PointsActionOut:
    brand = session.scalar(select(Brand).where(Brand.slug == body.brand_slug))
    if brand is None:
        raise HTTPException(status_code=404, detail="Unknown brand")
    try:
        awarded, _ = orders.record_order(session, user.id, brand, body.url)
    except orders.NotAnOrderPage:
        raise HTTPException(status_code=400, detail="Not an order confirmation page")
    return PointsActionOut(awarded=awarded, **_status(session, user.id, date.today()).model_dump())
