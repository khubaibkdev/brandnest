"""The deal verification state machine (ARCHITECTURE.md §8).

Both `sale_event` and `bank_offer` carry the same status columns and move through
the same states, so one module serves the admin desk and the worker alike.

    draft → needs_verification → verified → live → expired
       └────────── rejected (any pre-live state)     live → corrected (edit + re-verify)

Only a human sets `verified`; only the worker sets `live` and `expired`.
"""

import logging
from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_session
from app.models import Bank, BankOffer, Brand, SaleEvent
from app.services.notifications import send_topic_notification

logger = logging.getLogger(__name__)

DRAFT = "draft"
NEEDS_VERIFICATION = "needs_verification"
VERIFIED = "verified"
LIVE = "live"
EXPIRED = "expired"
REJECTED = "rejected"
CORRECTED = "corrected"

TRANSITIONS: dict[str, set[str]] = {
    DRAFT: {NEEDS_VERIFICATION, VERIFIED, REJECTED},
    NEEDS_VERIFICATION: {VERIFIED, REJECTED},
    VERIFIED: {LIVE, EXPIRED, REJECTED},
    LIVE: {EXPIRED, CORRECTED},
    CORRECTED: {VERIFIED, REJECTED},
    EXPIRED: set(),
    REJECTED: set(),
}

# What the shopper sees. Kept here so the app-facing endpoints and the desk agree.
PUBLISHED = (VERIFIED, LIVE)

# Human decisions. The rest of the machine belongs to the worker.
DESK_ACTIONS = (NEEDS_VERIFICATION, VERIFIED, REJECTED, CORRECTED)


class TransitionError(Exception):
    """A move the state machine does not allow."""


def desk_actions(status: str) -> list[str]:
    """The moves a person may make from `status` — the desk's buttons."""
    return [action for action in DESK_ACTIONS if action in TRANSITIONS.get(status, set())]


def transition(deal: SaleEvent | BankOffer, to_status: str, actor: str | None = None) -> None:
    """Move `deal` to `to_status`, or refuse.

    Verifying is the one transition that carries a burden of proof: it needs a
    proof URL and the name of the person who checked it, because that name is
    what the "Verified ✓" badge is ultimately claiming.
    """
    if to_status not in TRANSITIONS:
        raise TransitionError(f"{to_status} is not a status")
    if to_status not in TRANSITIONS[deal.status]:
        raise TransitionError(f"cannot go from {deal.status} to {to_status}")

    if to_status == VERIFIED:
        if not deal.proof_url:
            raise TransitionError("a deal cannot be verified without a proof link")
        if not actor:
            raise TransitionError("verification has to be signed by a person")
        deal.verified_by = actor
        deal.verified_at = datetime.now(timezone.utc)

    if to_status == REJECTED:
        # Kept as a record of who turned it down, not as a claim it is good.
        deal.verified_by = actor
        deal.verified_at = datetime.now(timezone.utc)

    deal.status = to_status


def run_deal_transitions(session: Session | None = None) -> dict[str, int]:
    """Publish deals whose window has opened and retire those whose window closed.

    Expiry is automatic because a stale deal on screen is worse than a live deal
    missed (ARCHITECTURE.md §8).
    """
    own_session = session is None
    session = session or get_session()
    counts = {"published": 0, "expired": 0}

    for deal, starts, ends in _dated_deals(session):
        started = starts is None or _has_passed(starts)
        finished = ends is not None and _has_passed(ends, inclusive=False)
        if deal.status == VERIFIED and started and not finished:
            transition(deal, LIVE)
            counts["published"] += 1
            _notify_live(session, deal)
        elif deal.status in (VERIFIED, LIVE) and finished:
            transition(deal, EXPIRED)
            counts["expired"] += 1

    session.commit()
    if own_session:
        session.close()
    logger.info("deal transitions: %s", counts)
    return counts


def _notify_live(session: Session, deal: SaleEvent | BankOffer) -> None:
    """Topic per brand for a sale, per bank for an offer (US-6).

    Every active brand gets a sale topic and every offer's bank gets an offer
    topic — there is no brand-follow feature to gate this on, so a device
    subscribes to all of them and the per-category toggle is the only opt-out.
    """
    if isinstance(deal, SaleEvent):
        brand = session.get(Brand, deal.brand_id)
        if brand is None:
            return
        send_topic_notification(
            f"sale-{brand.slug}",
            f"{brand.name} sale is live",
            deal.discount_text or deal.title,
            {"type": "sale", "brand_slug": brand.slug},
        )
    else:
        bank = session.get(Bank, deal.bank_id)
        if bank is None:
            return
        brand = session.get(Brand, deal.brand_id) if deal.brand_id else None
        scope = brand.name if brand else "all brands"
        send_topic_notification(
            f"offer-{bank.slug}",
            f"{bank.name} offer is live",
            f"{_offer_saving_text(deal)} at {scope}",
            {"type": "offer", "bank_slug": bank.slug},
        )


def _offer_saving_text(offer: BankOffer) -> str:
    if offer.discount_pct is not None:
        return f"{offer.discount_pct:g}% off"
    if offer.max_discount_amt is not None:
        return f"Up to Rs {offer.max_discount_amt:,.0f} off"
    return "New discount"


def _has_passed(moment: date | datetime, inclusive: bool = True) -> bool:
    """Offers carry plain dates, sale events carry timestamps; compare each in kind.

    `datetime` subclasses `date`, so the datetime check has to come first.
    """
    if isinstance(moment, datetime):
        now = datetime.now(timezone.utc)
        return moment <= now if inclusive else moment < now
    today = date.today()
    return moment <= today if inclusive else moment < today


def _dated_deals(session: Session):
    """Every deal the worker may move, paired with its own window columns."""
    offers = session.scalars(
        select(BankOffer).where(BankOffer.status.in_((VERIFIED, LIVE)))
    )
    sales = session.scalars(
        select(SaleEvent).where(SaleEvent.status.in_((VERIFIED, LIVE)))
    )
    for offer in offers:
        yield offer, offer.valid_from, offer.valid_to
    for sale in sales:
        yield sale, sale.starts_at, sale.ends_at
