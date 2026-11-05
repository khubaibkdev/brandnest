"""US-11: pushing the catalog into Meilisearch (ARCHITECTURE.md §2).

The index is a projection, not a second source of truth — every field is
derived from Postgres on each sync, so a wrong rule in `categories.py` is fixed
by re-running this, never by patching documents in place. That is also why the
canonical category lives here rather than in a `product` column: it is derived
data with exactly one consumer, and a migration would only give it somewhere
else to go stale.
"""

import logging
from collections.abc import Iterator

import meilisearch
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.config import settings
from app.models import Brand, Product, ProductVariant
from app.services.categories import classify

logger = logging.getLogger(__name__)

INDEX_NAME = "products"
BATCH_SIZE = 5000

# Roman-Urdu is written however it sounds, so these are transliteration
# variants, not meanings — the shopper typing "salwar qameez" and the brand
# writing "Shalwar Kameez" want the same rack. Meilisearch's own typo tolerance
# already covers single-letter slips; these are the spellings too far apart for
# it, and the English words a Pakistani shopper uses interchangeably.
SYNONYMS = {
    "kurta": ["kurti", "qurta", "kurtha"],
    "kurti": ["kurta"],
    "kameez": ["qameez", "kamiz", "kamees", "shirt"],
    "shalwar": ["salwar", "shalwaar", "salwaar"],
    "dupatta": ["dupata", "duppatta", "dopatta", "chunri"],
    "unstitched": ["unstiched", "un stitched", "unstitch", "kapra"],
    "khussa": ["khusa", "khussay", "khussas"],
    "chappal": ["chapal", "chappals", "sandal"],
    "joota": ["joota", "jooty", "juta", "shoes"],
    "peshawari": ["peshawri", "pashawari"],
    "waistcoat": ["koti", "waist coat"],
    "sherwani": ["shairwani"],
    "lehenga": ["lehnga", "lehanga", "langa"],
    "3 piece": ["3pc", "three piece", "3 pc"],
    "2 piece": ["2pc", "two piece", "2 pc"],
    "bacha": ["bachay", "kids", "bachon"],
    "larki": ["girls", "larkiyan"],
    "larka": ["boys", "larkay"],
    "aurat": ["women", "woman", "ladies"],
    "mard": ["men", "man", "gents"],
}


def client() -> meilisearch.Client:
    return meilisearch.Client(settings.meili_url, settings.meili_key)


def configure(search_client: meilisearch.Client | None = None) -> None:
    """Index settings. Ordered searchable attributes matter: a hit in the title
    should outrank the same word buried in a tag list."""
    index = (search_client or client()).index(INDEX_NAME)
    index.update_settings({
        "searchableAttributes": ["title", "raw_category", "category", "brand_name", "tags"],
        "filterableAttributes": [
            "brand_slug", "category", "raw_category", "audience", "price", "is_available",
        ],
        "sortableAttributes": ["price"],
        "synonyms": SYNONYMS,
    })


def build_documents(session: Session) -> Iterator[dict]:
    """One document per product of an active brand, priced by its cheapest
    variant — the number a listing shows and the one "under 3000" means.

    A product with no priced variant is skipped: it cannot answer a price
    filter, and there is nothing to click through to buy.
    """
    rows = session.execute(
        select(
            Product.id,
            Product.title,
            Product.category,
            Product.tags,
            Product.source_url,
            Product.image_urls,
            Product.is_available,
            Brand.slug,
            Brand.name,
            func.min(ProductVariant.price).label("price"),
            func.bool_or(ProductVariant.in_stock).label("in_stock"),
        )
        .join(Brand, Brand.id == Product.brand_id)
        .join(ProductVariant, ProductVariant.product_id == Product.id)
        .where(Brand.is_active)
        .group_by(Product.id, Brand.slug, Brand.name)
    )
    for row in rows:
        if row.price is None:
            continue
        classification = classify(row.title, row.category, row.tags)
        yield {
            "id": row.id,
            "title": row.title,
            "brand_slug": row.slug,
            "brand_name": row.name,
            "category": classification.category,
            # The brand's own shelf name. Not a filter people pick from a list
            # of 423, but the detail they want once they have drilled in, and
            # the words they actually type.
            "raw_category": row.category,
            "audience": classification.audience,
            "tags": row.tags[:20],
            "price": float(row.price),
            "url": row.source_url,
            "image": row.image_urls[0] if row.image_urls else None,
            "is_available": bool(row.is_available and row.in_stock),
        }


def reindex(session: Session, search_client: meilisearch.Client | None = None) -> dict:
    """Rebuild the whole index. Documents are keyed by product id, so this is
    an upsert — re-running it changes nothing that has not changed."""
    search_client = search_client or client()
    configure(search_client)
    index = search_client.index(INDEX_NAME)

    batch, indexed = [], 0
    for document in build_documents(session):
        batch.append(document)
        if len(batch) >= BATCH_SIZE:
            index.add_documents(batch)
            indexed += len(batch)
            batch = []
    if batch:
        index.add_documents(batch)
        indexed += len(batch)
    logger.info("search index: queued %s documents", indexed)
    return {"documents": indexed}


def run_reindex() -> dict:
    """Worker entrypoint: the nightly crawl changes prices and adds products,
    so the index is rebuilt after it rather than on its own schedule."""
    from app.db import engine

    with Session(engine) as session:
        return reindex(session)
