"""Scrape a bank's own deals listing and keep the merchants we carry (US-3/US-5).

Takes the whole listing the bank publishes rather than searching it brand by
brand: the bank decides what it is running, and we intersect that with our
catalogue afterwards. A brand we do not carry is simply dropped.

Needs a browser. These listings are React widgets — fetching the same URL with
httpx returns "You are using an outdated browser", 92 characters, no merchants
(measured 2026-09-05), so `offer_scan`'s crawler cannot see them at all.

Nothing scraped is published. Every match is filed `needs_verification` with
the listing URL as proof, for a named human to verify (decision 2026-07-27).
"""

import logging
import re

from sqlalchemy import select

from app.db import get_session
from app.models import Bank, BankOffer, Brand

logger = logging.getLogger(__name__)

# Where each bank's listing lives. `_all/all` rather than a category id:
# scanning only Clothing & Footwear missed eight other categories — including
# e-Stores, where online retailers sit — and would miss any category a bank
# adds later. Peekaboo powers several Pakistani banks on this same URL shape.
# Our bank slug -> its Peekaboo tenant. Probed 2026-09-06: these eleven resolve;
# Faysal, JS, Dubai Islamic, BankIslami, NBP, Summit and Silkbank have no tenant.
_TENANTS = {
    "hbl": "hbl",
    "mcb": "mcb",
    "ubl": "ubl",
    "meezan": "meezan",
    "bank-alfalah": "alfalah",
    "askari": "askari",
    "bank-al-habib": "bahl",
    "allied-bank": "allied",
    "soneri": "soneri",
    "habibmetro": "hmb",
    "bank-of-punjab": "bop",
}
BANK_LISTINGS = {
    slug: f"https://{tenant}-web.peekaboo.guru/{{city}}/places/_all/all"
    for slug, tenant in _TENANTS.items()
}
CITIES = ("karachi", "lahore", "islamabad")

# The widget renders each merchant as a card: name, then "Up to" for a ceiling
# offer, then the number. "Up to 30%" and a flat "15%" both end up as 30 and 15.
_CARD_RE = re.compile(
    r"^(?P<name>[^\n]{2,60}?)\s*\n+(?:Up\s*to\s*\n+)?(?P<pct>\d{1,2})\s*%\s*$",
    re.MULTILINE,
)

SOURCE = "bank-page"
PAGE_TIMEOUT_MS = 60_000
SEE_MORE_CLICKS = 20


def parse_listing(text: str) -> list[tuple[str, int]]:
    """Every (merchant, percentage) the rendered listing shows."""
    found = []
    for match in _CARD_RE.finditer(text):
        name = " ".join(match.group("name").split())
        percent = int(match.group("pct"))
        if name and (name, percent) not in found:
            found.append((name, percent))
    return found


def normalise(name: str) -> str:
    """Compare merchant names loosely enough to survive 'Khas Stores' vs
    'Khas', but not so loosely that 'Nike' matches 'Nishat'."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


def match_to_brands(listing: list[tuple[str, int]], brands: list[Brand]) -> list[tuple[Brand, int, str]]:
    """Keep only merchants we actually carry."""
    matched = []
    for merchant, percent in listing:
        merchant_key = normalise(merchant)
        for brand in brands:
            brand_key = normalise(brand.name)
            if merchant_key == brand_key or (
                len(brand_key) >= 5 and (brand_key in merchant_key or merchant_key in brand_key)
            ):
                matched.append((brand, percent, merchant))
                break
    return matched


def render_listing(url: str) -> str:
    """The listing's visible text, after JavaScript has populated it."""
    from playwright.sync_api import sync_playwright

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(args=["--no-sandbox"])
        try:
            page = browser.new_page()
            page.goto(url, timeout=PAGE_TIMEOUT_MS, wait_until="networkidle")
            for _ in range(SEE_MORE_CLICKS):
                more = page.get_by_text("See More", exact=True)
                if more.count() == 0:
                    break
                try:
                    more.first.click(timeout=5_000)
                    page.wait_for_timeout(2_500)
                except Exception:
                    break
            return page.inner_text("body")
        finally:
            browser.close()


def _already_filed(session, bank_id: int, brand_id: int, percent: int) -> bool:
    return session.scalar(
        select(BankOffer.id).where(
            BankOffer.bank_id == bank_id,
            BankOffer.brand_id == brand_id,
            BankOffer.discount_pct == percent,
        )
    ) is not None


def run_bank_scan() -> dict:
    """Worker entry point: read every configured bank listing, file what we carry."""
    session = get_session()
    stats = {"listings": 0, "merchants": 0, "matched": 0, "filed": 0}
    try:
        brands = session.scalars(select(Brand).where(Brand.is_active)).all()
        for slug, template in BANK_LISTINGS.items():
            bank = session.scalar(select(Bank).where(Bank.slug == slug))
            if bank is None:
                logger.info("%s: not seeded as a bank, skipped", slug)
                continue
            for city in CITIES:
                url = template.format(city=city)
                try:
                    listing = parse_listing(render_listing(url))
                except Exception:
                    logger.exception("%s/%s: listing unreadable", slug, city)
                    continue
                stats["listings"] += 1
                stats["merchants"] += len(listing)
                logger.info("%s/%s: %d merchants listed", slug, city, len(listing))

                for brand, percent, merchant in match_to_brands(listing, brands):
                    stats["matched"] += 1
                    if _already_filed(session, bank.id, brand.id, percent):
                        continue
                    session.add(
                        BankOffer(
                            bank_id=bank.id,
                            brand_id=brand.id,
                            discount_pct=percent,
                            proof_url=url[:500],
                            status="needs_verification",
                            source=SOURCE,
                        )
                    )
                    session.commit()
                    stats["filed"] += 1
                    logger.info(
                        "%s: %s %d%% (listed as %r) filed for verification",
                        slug, brand.name, percent, merchant,
                    )
    finally:
        session.close()
    logger.info("bank scan: %s", stats)
    return stats
