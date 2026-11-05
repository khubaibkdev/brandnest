"""Seed banks and a starter set of bank offers for the US-3 toolbar chips.

The banks are real and each `offer_page_url` was checked to resolve on 2026-07-26.

**The offers are development fixtures, not desk-verified deals.** Nobody has confirmed
these terms with any bank; they exist so the toolbar has something to render before the
deals desk (US-7) can enter real ones. Every fixture row carries `source='fixture'`, so
the whole set disappears with one statement before the closed beta:

    DELETE FROM bank_offer WHERE source = 'fixture';

Two fixtures are deliberately invisible ones — an out-of-window offer and a draft —
so the endpoint's filtering can be checked against the real database, not just in tests.
"""

from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select

from app.db import get_session
from app.models import Bank, BankOffer, Brand

FIXTURE_SOURCE = "fixture"

# (slug, name, offer_page_url)
BANKS = [
    ("standard-chartered", "Standard Chartered", "https://www.sc.com/pk/promotions/"),
    ("ubl", "UBL", "https://www.ubldigital.com/Personal/Cards/Offers"),
    ("meezan", "Meezan Bank", "https://www.meezanbank.com/card-discounts"),
    ("bank-alfalah", "Bank Alfalah",
     "https://www.bankalfalah.com/conventional/discounts-privileges"),
    ("mcb", "MCB Bank", "https://www.mcb.com.pk/personal/cards/deal-discounts"),
]

# (bank_slug, brand_slug | None = all brands, card_types, discount_pct,
#  max_discount_amt, min_spend, channel, status, valid_from_days, valid_to_days)
# Validity is expressed in days from the seed date so fixtures never quietly expire.
OFFERS = [
    ("standard-chartered", "outfitters", ["credit"], 15, 3000, 5000, "online", "live",
     -30, 60),
    ("ubl", "junaid-jamshed", ["credit", "debit"], 12, 4000, 3000, "both", "live",
     -14, 45),
    ("meezan", None, ["islamic", "debit"], 10, 2500, 2000, "online", "live", -60, 90),
    ("bank-alfalah", "limelight", ["credit"], 20, 5000, 6000, "both", "live", -7, 21),
    ("mcb", "alkaram-studio", ["credit", "debit"], 10, 2000, None, "online", "live",
     -3, 30),
    ("mcb", "bonanza-satrangi", ["credit"], 8, None, 2500, "instore", "live", -20, 40),
    # Must NOT reach the app: window closed even though the status job has not run yet.
    ("ubl", "outfitters", ["credit"], 25, 8000, 4000, "online", "live", -90, -5),
    # Must NOT reach the app: nobody has verified it.
    ("bank-alfalah", "outfitters", ["credit"], 30, 9000, 5000, "online", "draft", -5, 30),
]


def seed() -> None:
    session = get_session()
    banks_created = 0
    offers_created = 0
    offers_updated = 0

    for slug, name, offer_page_url in BANKS:
        bank = session.scalar(select(Bank).where(Bank.slug == slug))
        if bank is None:
            session.add(Bank(slug=slug, name=name, offer_page_url=offer_page_url))
            banks_created += 1
    session.flush()

    bank_ids = dict(session.execute(select(Bank.slug, Bank.id)).all())
    brand_ids = dict(session.execute(select(Brand.slug, Brand.id)).all())
    # The bank's own discounts page is the proof a shopper can check for themselves.
    offer_pages = {slug: url for slug, _, url in BANKS}
    today = date.today()

    for (bank_slug, brand_slug, card_types, discount_pct, max_discount_amt, min_spend,
         channel, status, valid_from_days, valid_to_days) in OFFERS:
        brand_id = brand_ids[brand_slug] if brand_slug else None
        # One fixture per bank × brand, which is what makes a re-run an update.
        offer = session.scalar(
            select(BankOffer).where(
                BankOffer.bank_id == bank_ids[bank_slug],
                BankOffer.brand_id.is_(None) if brand_id is None
                else BankOffer.brand_id == brand_id,
                BankOffer.source == FIXTURE_SOURCE,
            )
        )
        if offer is None:
            offer = BankOffer(bank_id=bank_ids[bank_slug], brand_id=brand_id,
                              source=FIXTURE_SOURCE)
            session.add(offer)
            offers_created += 1
        else:
            offers_updated += 1
        offer.card_types = card_types
        offer.discount_pct = discount_pct
        offer.max_discount_amt = max_discount_amt
        offer.min_spend = min_spend
        offer.channel = channel
        offer.status = status
        offer.valid_from = today + timedelta(days=valid_from_days)
        offer.valid_to = today + timedelta(days=valid_to_days)
        offer.proof_url = offer_pages[bank_slug]
        if status in ("verified", "live"):
            offer.verified_by = "dev-fixture"
            offer.verified_at = datetime.now(timezone.utc)

    session.commit()
    session.close()
    print(
        f"seeded {banks_created} new banks ({len(BANKS) - banks_created} already present); "
        f"{offers_created} fixture offers created, {offers_updated} refreshed"
    )


if __name__ == "__main__":
    seed()
