"""The points ledger (US-10): append-only, idempotent, balance = SUM(delta).

Every award goes through [award_points], which leans on the same
`on_conflict_do_nothing` shape `app.auth.get_or_create_user` already uses — a
retried request with the same `idempotency_key` is a no-op, not a duplicate.
"""

from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.models import PointsLedger

CHECKIN_POINTS = 10
REWARDED_AD_POINTS = 20
REWARDED_AD_DAILY_CAP = 5


def award_points(
    session: Session,
    user_id: int,
    delta: int,
    reason: str,
    idempotency_key: str,
    ref_id: str | None = None,
    status: str = "confirmed",
) -> bool:
    """Insert a ledger row. Returns False, without erroring, if
    `idempotency_key` was already used — the caller decides what a no-op means.

    `status` is `confirmed` for awards that are final the moment they happen.
    US-18 passes `pending` for order points, which [balance] excludes until
    the hold has run."""
    result = session.execute(
        insert(PointsLedger)
        .values(
            user_id=user_id,
            delta=delta,
            reason=reason,
            ref_id=ref_id,
            idempotency_key=idempotency_key,
            status=status,
        )
        .on_conflict_do_nothing(index_elements=["idempotency_key"])
        .returning(PointsLedger.id)
    )
    # ON CONFLICT DO NOTHING returns no row when it conflicts, one when it
    # inserted — a far more reliable signal here than `rowcount`.
    inserted = result.first() is not None
    session.commit()
    return inserted


def balance(session: Session, user_id: int) -> int:
    return session.scalar(
        select(func.coalesce(func.sum(PointsLedger.delta), 0)).where(
            PointsLedger.user_id == user_id, PointsLedger.status == "confirmed"
        )
    )


def pending_balance(session: Session, user_id: int) -> int:
    """Points awarded but still inside their hold window (US-18)."""
    return session.scalar(
        select(func.coalesce(func.sum(PointsLedger.delta), 0)).where(
            PointsLedger.user_id == user_id, PointsLedger.status == "pending"
        )
    )


def has_checked_in(session: Session, user_id: int, day: date) -> bool:
    return (
        session.scalar(
            select(PointsLedger.id).where(
                PointsLedger.user_id == user_id,
                PointsLedger.reason == "streak",
                PointsLedger.ref_id == day.isoformat(),
                PointsLedger.status == "confirmed",
            )
        )
        is not None
    )


def rewarded_ads_watched(session: Session, user_id: int, day: date) -> int:
    return session.scalar(
        select(func.count())
        .select_from(PointsLedger)
        .where(
            PointsLedger.user_id == user_id,
            PointsLedger.reason == "rewarded_ad",
            PointsLedger.status == "confirmed",
            func.date(PointsLedger.created_at) == day,
        )
    )


def current_streak(session: Session, user_id: int, today: date) -> int:
    """Consecutive check-in days, counting back from today if already checked
    in, or from yesterday otherwise — a streak isn't broken until a whole day
    passes with no check-in, so this doesn't drop to 0 the moment the clock
    rolls over into a day the shopper hasn't opened the app yet."""
    checked_in_days = {
        date.fromisoformat(ref_id)
        for ref_id in session.scalars(
            select(PointsLedger.ref_id).where(
                PointsLedger.user_id == user_id,
                PointsLedger.reason == "streak",
                PointsLedger.status == "confirmed",
            )
        )
        if ref_id
    }
    day = today if today in checked_in_days else today - timedelta(days=1)
    streak = 0
    while day in checked_in_days:
        streak += 1
        day -= timedelta(days=1)
    return streak
