"""Community deal reporting (US-14).

ARCHITECTURE.md §8 already had the shape: a community `deal_report` is one of
the three things that can create a draft deal, and "verifying a community
report awards points via `points_ledger` (idempotent)". This is that path.

Two rules the desk cannot break by clicking twice:

* Points are awarded through `points.award_points` under a key derived from the
  report id, so a second accept adds nothing.
* A report that has already been decided stays decided. Re-deciding it would
  push a second notification at someone about a report they already heard about.
"""

import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import DealReport, DeviceToken
from app.services import points
from app.services.notifications import send_device_notification

logger = logging.getLogger(__name__)

NEW = "new"
ACCEPTED = "accepted"
REJECTED = "rejected"
DECIDED = (ACCEPTED, REJECTED)

# Worth more than a check-in (10) or a rewarded ad (20): reporting a real deal
# takes a screenshot and someone's attention, and it is the only one of the
# three that produces something another shopper can use.
REPORT_POINTS = 50


class AlreadyDecided(Exception):
    """The desk has already accepted or rejected this report."""


def create_report(
    session: Session, user_id: int, text: str | None, screenshot_url: str | None
) -> DealReport:
    report = DealReport(
        user_id=user_id,
        text=text or None,
        screenshot_url=screenshot_url,
        status=NEW,
    )
    session.add(report)
    session.commit()
    return report


def reports_for_user(session: Session, user_id: int) -> list[DealReport]:
    return list(
        session.scalars(
            select(DealReport)
            .where(DealReport.user_id == user_id)
            .order_by(DealReport.created_at.desc())
        )
    )


def pending_reports(session: Session) -> list[DealReport]:
    return list(
        session.scalars(
            select(DealReport)
            .where(DealReport.status == NEW)
            .order_by(DealReport.created_at)
        )
    )


def accept(session: Session, report: DealReport) -> DealReport:
    """Accept, award the points once, and tell the reporter."""
    _require_undecided(report)
    report.status = ACCEPTED
    awarded = points.award_points(
        session,
        user_id=report.user_id,
        delta=REPORT_POINTS,
        reason="deal_report",
        # The report can only ever pay out once, however many times this runs.
        idempotency_key=f"deal_report:{report.id}",
        ref_id=str(report.id),
    )
    if awarded:
        report.points_awarded = REPORT_POINTS
    session.commit()
    _notify(
        session,
        report,
        "Your deal was verified",
        f"Thanks — {REPORT_POINTS} points are in your balance.",
    )
    return report


def reject(session: Session, report: DealReport) -> DealReport:
    _require_undecided(report)
    report.status = REJECTED
    session.commit()
    _notify(
        session,
        report,
        "We could not verify that deal",
        "Thanks for sending it in — nothing was added this time.",
    )
    return report


def _require_undecided(report: DealReport) -> None:
    if report.status in DECIDED:
        raise AlreadyDecided(f"Report {report.id} is already {report.status}")


def _notify(session: Session, report: DealReport, title: str, body: str) -> None:
    """Tell the reporter what happened. A shopper with no registered device
    simply does not hear about it — the report's own status still changed, so
    this never blocks the desk."""
    tokens = session.scalars(
        select(DeviceToken.fcm_token).where(DeviceToken.user_id == report.user_id)
    )
    for token in tokens:
        send_device_notification(
            token, title, body, {"type": "report", "report_id": str(report.id)}
        )
