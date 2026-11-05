import logging
from collections.abc import Iterable
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.crawlers.base import NormalizedProduct, NormalizedVariant
from app.models import Brand, PriceHistory, Product, ProductVariant

logger = logging.getLogger(__name__)

COMMIT_BATCH_SIZE = 100
STALE_AFTER_DAYS = 2  # missing from ~2 consecutive nightly crawls → unavailable


def ingest_products(
    session: Session, brand: Brand, products: Iterable[NormalizedProduct]
) -> dict:
    stats = {"products_seen": 0, "products_new": 0, "history_rows": 0}
    for normalized in products:
        stats["products_seen"] += 1
        observed_at = datetime.now(timezone.utc)
        product = _upsert_product(session, brand, normalized, observed_at, stats)
        existing = {v.external_id: v for v in product.variants}
        for normalized_variant in normalized.variants:
            stats["history_rows"] += _upsert_variant(
                session, product, existing.get(normalized_variant.external_id),
                normalized_variant, observed_at,
            )
        if stats["products_seen"] % COMMIT_BATCH_SIZE == 0:
            session.commit()
    session.commit()
    return stats


def _upsert_product(
    session: Session,
    brand: Brand,
    normalized: NormalizedProduct,
    observed_at: datetime,
    stats: dict,
) -> Product:
    product = session.execute(
        select(Product).where(
            Product.brand_id == brand.id,
            Product.external_id == normalized.external_id,
        )
    ).scalar_one_or_none()
    if product is None:
        product = Product(brand_id=brand.id, external_id=normalized.external_id)
        session.add(product)
        stats["products_new"] += 1
    product.source_url = normalized.source_url
    product.title = normalized.title
    product.description = normalized.description
    product.category = normalized.category
    product.tags = normalized.tags
    product.image_urls = normalized.image_urls
    product.last_seen = observed_at
    product.is_available = True
    session.flush()
    return product


def _upsert_variant(
    session: Session,
    product: Product,
    variant: ProductVariant | None,
    normalized: NormalizedVariant,
    observed_at: datetime,
) -> int:
    """Update or create the variant. Returns 1 if a price_history row was written."""
    if variant is None:
        variant = ProductVariant(
            product_id=product.id,
            external_id=normalized.external_id,
            size=normalized.size,
            color=normalized.color,
            price=normalized.price,
            compare_at_price=normalized.compare_at_price,
            in_stock=normalized.in_stock,
            last_checked=observed_at,
        )
        session.add(variant)
        session.flush()
        _record_history(session, variant, observed_at)
        return 1

    changed = (
        variant.price != normalized.price
        or variant.compare_at_price != normalized.compare_at_price
        or variant.in_stock != normalized.in_stock
    )
    variant.size = normalized.size
    variant.color = normalized.color
    variant.last_checked = observed_at
    if not changed:
        return 0
    variant.price = normalized.price
    variant.compare_at_price = normalized.compare_at_price
    variant.in_stock = normalized.in_stock
    _record_history(session, variant, observed_at)
    return 1


def _record_history(session: Session, variant: ProductVariant, observed_at: datetime) -> None:
    session.add(
        PriceHistory(
            variant_id=variant.id,
            price=variant.price,
            compare_at_price=variant.compare_at_price,
            in_stock=variant.in_stock,
            observed_at=observed_at,
        )
    )


def mark_stale_unavailable(session: Session, brand: Brand) -> int:
    cutoff = datetime.now(timezone.utc) - timedelta(days=STALE_AFTER_DAYS)
    result = session.execute(
        update(Product)
        .where(Product.brand_id == brand.id, Product.last_seen < cutoff, Product.is_available)
        .values(is_available=False)
    )
    session.commit()
    if result.rowcount:
        logger.info("%s: marked %d products unavailable", brand.slug, result.rowcount)
    return result.rowcount
