"""US-13: the hourly re-check for every actively-watched product (Tier-W,
CRAWLER_PLAYBOOK §2).

Re-fetches just the watched products — one product per request via
`crawlers.shopify.fetch_one_product` / `crawlers.sitemap_html.fetch_one_product`
— rather than waiting for the nightly full-catalog crawl, so a watched item's
price or stock change is caught within the hour instead of by the next
morning. Reuses `ingest_products` so the change lands in `price_history`
exactly the way a normal crawl would; nothing here writes to the catalog a
second, different way.
"""

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.crawlers import shopify, sitemap_html
from app.crawlers.base import CrawlBlocked, NormalizedProduct, PoliteFetcher
from app.db import get_session
from app.models import Brand, DeviceToken, Product, WatchItem
from app.pipeline.ingest import ingest_products
from app.services.notifications import send_device_notification

logger = logging.getLogger(__name__)

# A watch that already fired inside the last hour doesn't fire again for the
# same still-true condition — "alert within one Tier-W cycle" means once,
# not every cycle for as long as the price stays down.
RENOTIFY_AFTER = timedelta(hours=1)


def run_watch_alerts(session: Session | None = None) -> dict[str, int]:
    own_session = session is None
    session = session or get_session()
    counts = {"checked": 0, "notified": 0}

    fetcher = PoliteFetcher()
    try:
        for product in _watched_products(session):
            counts["checked"] += 1
            try:
                _recheck_and_notify(session, product, fetcher, counts)
            except CrawlBlocked as blocked:
                session.rollback()
                logger.warning(
                    "watch recheck blocked for product %d: %s", product.id, blocked
                )
            except Exception:
                session.rollback()
                logger.exception("watch recheck failed for product %d", product.id)
    finally:
        fetcher.close()
        if own_session:
            session.close()
    logger.info("watch alerts: %s", counts)
    return counts


def _watched_products(session: Session) -> list[Product]:
    product_ids = session.scalars(
        select(WatchItem.product_id).where(WatchItem.product_id.is_not(None)).distinct()
    )
    return list(session.scalars(select(Product).where(Product.id.in_(list(product_ids)))))


def _recheck_and_notify(
    session: Session, product: Product, fetcher: PoliteFetcher, counts: dict
) -> None:
    before = {v.id: (v.price, v.in_stock) for v in product.variants}
    if not before:
        return

    brand = session.get(Brand, product.brand_id)
    normalized = _fetch_one(brand, product.source_url, fetcher)
    if normalized is None:
        return

    ingest_products(session, brand, [normalized])

    price_dropped = any(v.id in before and v.price < before[v.id][0] for v in product.variants)
    restocked = any(
        v.id in before and v.in_stock and not before[v.id][1] for v in product.variants
    )
    kinds = {kind for kind, fired in (("price_drop", price_dropped), ("restock", restocked)) if fired}
    if kinds:
        _notify_watchers(session, product, kinds, counts)


def _fetch_one(brand: Brand, url: str, fetcher: PoliteFetcher) -> NormalizedProduct | None:
    if brand.platform == "shopify":
        return shopify.fetch_one_product(url, fetcher)
    if brand.platform == "salesforce_cc":
        return sitemap_html.fetch_one_product(url, fetcher)
    return None


def _notify_watchers(session: Session, product: Product, kinds: set[str], counts: dict) -> None:
    cutoff = datetime.now(timezone.utc) - RENOTIFY_AFTER
    watch_rows = session.scalars(
        select(WatchItem).where(WatchItem.product_id == product.id, WatchItem.kind.in_(kinds))
    )
    for watch in watch_rows:
        if watch.last_notified_at is not None and watch.last_notified_at > cutoff:
            continue
        tokens = session.scalars(
            select(DeviceToken.fcm_token).where(DeviceToken.user_id == watch.user_id)
        )
        title, body = _message_for(watch.kind, product)
        sent = any(
            send_device_notification(token, title, body, {"type": "watch", "product_id": str(product.id)})
            for token in tokens
        )
        if sent:
            watch.last_notified_at = datetime.now(timezone.utc)
            counts["notified"] += 1
    session.commit()


def _message_for(kind: str, product: Product) -> tuple[str, str]:
    if kind == "restock":
        return "Back in stock", f"{product.title} is available again"
    cheapest = min((v.price for v in product.variants), default=None)
    price_text = f" — now Rs {cheapest:,.0f}" if cheapest is not None else ""
    return "Price drop", f"{product.title}{price_text}"
