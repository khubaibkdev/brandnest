from datetime import date, datetime, time, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.db import db_session
from app.models import Brand, SaleEvent
from app.services import deals

router = APIRouter(tags=["sales"])

# A calendar that hides last week's Eid sale is a strange calendar, so events the
# desk approved stay visible after they end — the app just stops badging them.
VISIBLE_STATUSES = (*deals.PUBLISHED, deals.EXPIRED)

DEFAULT_PAST_DAYS = 30
DEFAULT_FUTURE_DAYS = 90


class SaleEventOut(BaseModel):
    id: int
    brand_slug: str
    brand_name: str
    title: str
    discount_text: str | None
    starts_at: datetime | None
    ends_at: datetime | None
    status: str
    proof_url: str | None


@router.get("/sales", response_model=list[SaleEventOut])
def list_sales(
    from_: date | None = Query(None, alias="from"),
    to: date | None = None,
    session: Session = Depends(db_session),
) -> list[SaleEventOut]:
    """Sale events overlapping a date window, oldest start first.

    An event with no dates is a sale the brand is running without announcing
    when it ends; it overlaps every window until the desk retires it.
    """
    today = date.today()
    window_start = _start_of(from_ or today - timedelta(days=DEFAULT_PAST_DAYS))
    window_end = _end_of(to or today + timedelta(days=DEFAULT_FUTURE_DAYS))

    stmt = (
        select(SaleEvent, Brand.slug, Brand.name)
        .join(Brand, Brand.id == SaleEvent.brand_id)
        .where(
            SaleEvent.status.in_(VISIBLE_STATUSES),
            or_(SaleEvent.starts_at.is_(None), SaleEvent.starts_at <= window_end),
            or_(SaleEvent.ends_at.is_(None), SaleEvent.ends_at >= window_start),
        )
        .order_by(SaleEvent.starts_at.asc().nullsfirst(), SaleEvent.id)
    )
    return [
        SaleEventOut(
            id=sale.id,
            brand_slug=slug,
            brand_name=name,
            title=sale.title,
            discount_text=sale.discount_text,
            starts_at=sale.starts_at,
            ends_at=sale.ends_at,
            status=sale.status,
            proof_url=sale.proof_url,
        )
        for sale, slug, name in session.execute(stmt)
    ]


def _start_of(day: date) -> datetime:
    return datetime.combine(day, time.min, tzinfo=timezone.utc)


def _end_of(day: date) -> datetime:
    return datetime.combine(day, time.max, tzinfo=timezone.utc)
