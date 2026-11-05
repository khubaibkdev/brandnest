"""US-12: a product's price series and the "Asli Sale" verdict.

The rules are CRAWLER_PLAYBOOK.md §3: a discount is genuine only if the price
is below its own recent typical level *and* was not raised shortly beforehand
so it could be "discounted" back down.

Two properties of the stored data shape everything here:

* `price_history` holds one row **per variant**, inserted only when something
  changed. A shopper sees one price on the product page, so the series is the
  cheapest variant on each day — reconstructed per variant first, because at
  any given crawl only the variants that actually moved have a row.
* Because rows exist only on change, counting rows would let a price that held
  for one day outweigh one that held for a month. Sampling the step function
  once per day and taking the median of *those* is the time-weighted answer,
  which is the one the badge needs to be honest.
"""

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from decimal import Decimal
from collections.abc import Mapping, Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import PriceHistory, ProductVariant

WINDOW_DAYS = 90
MARKUP_LOOKBACK_DAYS = 21

GENUINE = "genuine"
NOT_LOWEST = "not_lowest"
PRE_SALE_MARKUP = "pre_sale_markup"
NO_HISTORY = "no_history"


@dataclass(frozen=True)
class PricePoint:
    on: date
    price: Decimal


@dataclass(frozen=True)
class PriceReport:
    points: list[PricePoint]
    verdict: str
    current_price: Decimal | None
    typical_price: Decimal | None
    lowest_price: Decimal | None

    @property
    def window_days(self) -> int:
        """Days actually covered, not the 90 the rule is written against — the
        app labels the badge with this, so a young catalog never overclaims."""
        return len(self.points)


def build_report(
    variant_rows: Mapping[int, Sequence[tuple[datetime, Decimal]]],
    through: date,
    window_days: int = WINDOW_DAYS,
) -> PriceReport:
    points = daily_prices(variant_rows, through, window_days)
    if not points:
        return PriceReport([], NO_HISTORY, None, None, None)

    prices = [point.price for point in points]
    current = prices[-1]
    typical = _median(prices)
    report = PriceReport(points, GENUINE, current, typical, min(prices))
    if current >= typical:
        return _with_verdict(report, NOT_LOWEST)
    if _was_marked_up(points):
        return _with_verdict(report, PRE_SALE_MARKUP)
    return report


def daily_prices(
    variant_rows: Mapping[int, Sequence[tuple[datetime, Decimal]]],
    through: date,
    window_days: int = WINDOW_DAYS,
) -> list[PricePoint]:
    """One point per day: the cheapest variant that day, carried forward across
    days where nothing changed."""
    timelines = [_timeline(rows) for rows in variant_rows.values() if rows]
    if not timelines:
        return []

    first_seen = min(timeline[0][0] for timeline in timelines)
    day = max(first_seen, through - timedelta(days=window_days - 1))
    points = []
    while day <= through:
        prices = [
            price
            for price in (_price_on(timeline, day) for timeline in timelines)
            if price is not None
        ]
        if prices:
            points.append(PricePoint(on=day, price=min(prices)))
        day += timedelta(days=1)
    return points


def load_variant_rows(
    session: Session, product_id: int
) -> dict[int, list[tuple[datetime, Decimal]]]:
    """Every observation for the product's variants, oldest first. The whole
    history is read, not just the window: a price set long ago and never
    changed since has its only row outside the window, and dropping it would
    leave today looking like the first price we ever saw."""
    rows = session.execute(
        select(PriceHistory.variant_id, PriceHistory.observed_at, PriceHistory.price)
        .join(ProductVariant, ProductVariant.id == PriceHistory.variant_id)
        .where(ProductVariant.product_id == product_id)
        .order_by(PriceHistory.observed_at)
    )
    by_variant: dict[int, list[tuple[datetime, Decimal]]] = {}
    for variant_id, observed_at, price in rows:
        by_variant.setdefault(variant_id, []).append((observed_at, price))
    return by_variant


def _timeline(rows: Sequence[tuple[datetime, Decimal]]) -> list[tuple[date, Decimal]]:
    """Collapse one variant's rows to the price in effect at the end of each day
    it changed. Several changes within a day leave only the last one standing,
    which is what that day closed at."""
    by_day: dict[date, Decimal] = {}
    for observed_at, price in sorted(rows, key=lambda row: row[0]):
        by_day[observed_at.date()] = price
    return sorted(by_day.items())


def _price_on(timeline: Sequence[tuple[date, Decimal]], day: date) -> Decimal | None:
    """The variant's price on `day`: the most recent change at or before it.
    None before the variant was ever seen — a product that gained a variant
    later should not read as having been cheap before it existed."""
    price = None
    for changed_on, changed_to in timeline:
        if changed_on > day:
            break
        price = changed_to
    return price


def _was_marked_up(points: Sequence[PricePoint]) -> bool:
    """The "raised, then discounted back" pattern. A rise inside the lookback
    window means the peak the discount is measured against was manufactured
    there — the caller has already established that today sits below it."""
    window = points[-MARKUP_LOOKBACK_DAYS:]
    return max(point.price for point in window) > window[0].price


def _median(prices: Sequence[Decimal]) -> Decimal:
    ordered = sorted(prices)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) / 2


def _with_verdict(report: PriceReport, verdict: str) -> PriceReport:
    return PriceReport(
        report.points, verdict, report.current_price,
        report.typical_price, report.lowest_price,
    )
