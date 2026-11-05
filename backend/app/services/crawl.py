import logging

from sqlalchemy import select

from app.crawlers import category_html, shopify, sitemap_html
from app.crawlers.base import CrawlBlocked, PoliteFetcher
from app.db import get_session
from app.models import Brand, BrandConfig
from app.pipeline.ingest import ingest_products, mark_stale_unavailable

logger = logging.getLogger(__name__)


def run_full_crawl(brand_slugs: list[str] | None = None) -> None:
    """Tier F: full catalog crawl of active brands (see CRAWLER_PLAYBOOK.md §2)."""
    session = get_session()
    query = select(Brand).where(Brand.is_active)
    if brand_slugs:
        query = query.where(Brand.slug.in_(brand_slugs))
    brands = session.scalars(query).all()
    logger.info("full crawl starting: %d brands", len(brands))

    fetcher = PoliteFetcher()
    try:
        for brand in brands:
            config = session.get(BrandConfig, brand.id)
            if config is None:
                logger.info("%s: skipped (no brand_config)", brand.slug)
                continue
            try:
                products = _products_for(brand, config, fetcher)
                if products is None:
                    continue
                stats = ingest_products(session, brand, products)
                mark_stale_unavailable(session, brand)
                logger.info("%s: %s", brand.slug, stats)
            except CrawlBlocked as blocked:
                # Playbook §6: back off and stop this brand; humans investigate.
                session.rollback()
                logger.warning("%s: BLOCKED (%s) — brand skipped this run", brand.slug, blocked)
            except Exception:
                session.rollback()
                logger.exception("%s: crawl failed", brand.slug)
    finally:
        fetcher.close()
        session.close()
    logger.info("full crawl finished")


def _products_for(brand: Brand, config: BrandConfig, fetcher: PoliteFetcher):
    """The right adapter for `brand.platform`, or None (already logged) if it
    isn't crawlable this run."""
    if brand.platform == "shopify":
        if not config.products_json_ok:
            logger.info("%s: skipped (no open products.json)", brand.slug)
            return None
        return shopify.fetch_products(brand.website_url, fetcher)
    if brand.platform == "salesforce_cc":
        if not config.sitemap_url:
            logger.info("%s: skipped (no sitemap_url configured)", brand.slug)
            return None
        if config.sitemap_lists == "categories":
            return category_html.fetch_products(config.sitemap_url, fetcher)
        return sitemap_html.fetch_products(config.sitemap_url, fetcher)
    logger.info("%s: skipped (no crawler for platform %s)", brand.slug, brand.platform)
    return None
