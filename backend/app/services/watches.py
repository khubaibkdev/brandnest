"""Price-watch / restock alerts (US-13).

A watch toggle activating on a product creates two rows — a `price_drop`
watch and a `restock` watch — so "watch this" means either kind of good news,
not a choice the shopper has to make up front. `run_watch_alerts` (the
hourly job) re-checks each watched product and fires whichever kind actually
happened.
"""

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models import Brand, Product, WatchItem

KINDS = ("price_drop", "restock")


def find_product_by_url(session: Session, brand_slug: str, url: str) -> Product | None:
    """Match a URL the app saw in-browser to a crawled product, scoped to its
    brand so two brands' `/products/x` handles can never collide."""
    return session.scalar(
        select(Product)
        .join(Brand, Brand.id == Product.brand_id)
        .where(Brand.slug == brand_slug, Product.source_url == normalize_url(url))
    )


def is_watching(session: Session, user_id: int, product_id: int) -> bool:
    return (
        session.scalar(
            select(WatchItem.id).where(
                WatchItem.user_id == user_id, WatchItem.product_id == product_id
            )
        )
        is not None
    )


def start_watching(session: Session, user_id: int, product_id: int) -> None:
    existing = {
        kind
        for (kind,) in session.execute(
            select(WatchItem.kind).where(
                WatchItem.user_id == user_id, WatchItem.product_id == product_id
            )
        )
    }
    for kind in KINDS:
        if kind not in existing:
            session.add(WatchItem(user_id=user_id, product_id=product_id, kind=kind))
    session.commit()


def stop_watching(session: Session, user_id: int, product_id: int) -> None:
    session.execute(
        delete(WatchItem).where(
            WatchItem.user_id == user_id, WatchItem.product_id == product_id
        )
    )
    session.commit()


def normalize_url(url: str) -> str:
    return url.split("?")[0].split("#")[0].rstrip("/")
