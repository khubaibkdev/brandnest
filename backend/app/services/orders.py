"""Points for a completed order (US-18).

The app reports the confirmation page it landed on; this module decides
whether that page really is one. The check is repeated here rather than
trusted from the client, because the client's copy of the patterns came from
an API anyone can call and the reward is real.

Points land as `pending`, not `confirmed`: at detection time all we know is
that a thank-you page rendered, which an order can still be cancelled or
returned after. `balance()` already counts confirmed rows only, so pending
points are visible without being spendable, and `confirm_due_orders` promotes
them once the hold has passed. IMPLEMENTATION_PLAN's top risk calls this the
pending-points state.
"""

import logging
import re
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update

from app.db import get_session
from app.models import BrandConfig, PointsLedger
from app.services import points

logger = logging.getLogger(__name__)

ORDER_POINTS = 100
# Long enough to cover a normal return window, so points confirm at roughly
# the moment the sale becomes final.
HOLD_DAYS = 14
REASON = "order_confirmed"


class NotAnOrderPage(Exception):
    """The reported URL does not match any of the brand's patterns."""


def matches_order_page(url: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        try:
            if re.search(pattern, url):
                return True
        except re.error:
            # A bad pattern is a desk typo, not a reason to refuse every order.
            continue
    return False


def record_order(session, user_id: int, brand, url: str) -> tuple[bool, int]:
    """Award pending points for `url`. Returns `(awarded, points)`, where
    `awarded` is False when this order was already counted."""
    config = session.get(BrandConfig, brand.id)
    patterns = config.order_confirm_patterns if config else []
    if not matches_order_page(url, patterns):
        raise NotAnOrderPage(url)

    awarded = points.award_points(
        session,
        user_id=user_id,
        delta=ORDER_POINTS,
        reason=REASON,
        # The confirmation URL carries the order's own token, so it is the
        # order's identity; re-opening the page must not pay twice.
        idempotency_key=f"{REASON}:{brand.slug}:{url}",
        ref_id=brand.slug,
        status="pending",
    )
    return awarded, ORDER_POINTS


def confirm_due_orders(session, now: datetime | None = None) -> int:
    """Promote pending order points whose hold has elapsed. Returns how many."""
    cutoff = (now or datetime.now(timezone.utc)) - timedelta(days=HOLD_DAYS)
    due = session.scalars(
        select(PointsLedger.id).where(
            PointsLedger.reason == REASON,
            PointsLedger.status == "pending",
            PointsLedger.created_at <= cutoff,
        )
    ).all()
    if due:
        session.execute(
            update(PointsLedger)
            .where(PointsLedger.id.in_(due))
            .values(status="confirmed")
        )
        session.commit()
    return len(due)


def run_order_confirmations() -> dict:
    """Worker entry point: promote order points whose hold has elapsed."""
    session = get_session()
    try:
        confirmed = confirm_due_orders(session)
    finally:
        session.close()
    stats = {"confirmed": confirmed}
    logger.info("order confirmations: %s", stats)
    return stats
