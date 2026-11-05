from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db import db_session
from app.models import Product
from app.services import price_history

router = APIRouter(tags=["products"])


class PricePointOut(BaseModel):
    on: str
    # Money is float on the wire so the JSON stays a number, as US-3's offers
    # already do; the Decimal maths all happens before this point.
    price: float


class PriceHistoryOut(BaseModel):
    points: list[PricePointOut]
    # Days the series actually covers. The Asli Sale rule is written against 90
    # days, but the crawl is younger than that — the app labels the badge with
    # this number rather than claiming a window we don't have.
    window_days: int
    current_price: float | None
    typical_price: float | None
    lowest_price: float | None
    verdict: str


@router.get("/products/{product_id}/price-history", response_model=PriceHistoryOut)
def product_price_history(
    product_id: int, session: Session = Depends(db_session)
) -> PriceHistoryOut:
    """The price graph and Asli Sale verdict for one product. Unauthenticated:
    what a product has cost is the same fact for everyone."""
    if session.get(Product, product_id) is None:
        raise HTTPException(status_code=404, detail="Unknown product")
    report = price_history.build_report(
        price_history.load_variant_rows(session, product_id),
        through=datetime.now(timezone.utc).date(),
    )
    return PriceHistoryOut(
        points=[
            PricePointOut(on=point.on.isoformat(), price=float(point.price))
            for point in report.points
        ],
        window_days=report.window_days,
        current_price=_as_float(report.current_price),
        typical_price=_as_float(report.typical_price),
        lowest_price=_as_float(report.lowest_price),
        verdict=report.verdict,
    )


def _as_float(value) -> float | None:
    return None if value is None else float(value)
