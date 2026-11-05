"""US-3/US-5: scraping a bank's own deals listing and keeping what we carry.

The fixture text is the real rendered output of HBL's Islamabad Clothing &
Footwear listing on 2026-09-05, so the parser is pinned against the actual
shape rather than an invented one.
"""

import pytest
from sqlalchemy import select

from app.models import Brand
from app.services import bank_scan

HBL_ISLAMABAD = """Enter Keyword
trending_up

Trending

keyboard_arrow_down

Clothing & Footwear

close
credit_cards

HBL Cards

keyboard_arrow_down

Charles & Keith

Up to

30%

Nike

Up to

30%

ChenOne

15%

Khas Stores

15%

Almas Collection Jewelers

Up to

25%

Mothercare

20%

Souk Galleria

Up to

25%

TAG Heuer

Up to

20%

BOSS Store

25%

POLICE

Up to

20%

Danish Design Watches

Up to

20%

U.S. Polo Assn.

Up to

20%

Timex

Up to

20%
"""


def test_the_whole_listing_is_read_not_just_our_brands():
    """The bank decides what it runs; we intersect afterwards."""
    listing = bank_scan.parse_listing(HBL_ISLAMABAD)

    assert len(listing) == 13
    assert ("Khas Stores", 15) in listing
    assert ("Charles & Keith", 30) in listing
    assert ("Timex", 20) in listing


def test_up_to_and_flat_percentages_both_parse():
    listing = dict(bank_scan.parse_listing(HBL_ISLAMABAD))

    assert listing["Nike"] == 30
    assert listing["ChenOne"] == 15


def test_the_filter_chrome_is_not_read_as_a_merchant():
    names = [name for name, _ in bank_scan.parse_listing(HBL_ISLAMABAD)]

    assert "HBL Cards" not in names
    assert "Trending" not in names
    assert "Clothing & Footwear" not in names


@pytest.fixture
def brands(session):
    rows = session.scalars(
        select(Brand).where(Brand.slug.in_(["khas-stores", "nishat-linen", "outfitters"]))
    ).all()
    assert rows, "brands are not seeded"
    return list(rows)


def test_only_merchants_we_carry_survive(brands):
    matched = bank_scan.match_to_brands(bank_scan.parse_listing(HBL_ISLAMABAD), brands)

    assert [(brand.slug, pct) for brand, pct, _ in matched] == [("khas-stores", 15)]


def test_the_listed_name_is_kept_for_the_desk_to_check(brands):
    _, _, merchant = bank_scan.match_to_brands(
        bank_scan.parse_listing(HBL_ISLAMABAD), brands
    )[0]

    assert merchant == "Khas Stores"


def test_a_short_brand_name_does_not_match_on_a_substring(brands):
    """"Nike" must not match "Nishat"; only names of 5+ characters are allowed
    to match as substrings at all."""
    matched = bank_scan.match_to_brands([("Nike", 30)], brands)

    assert matched == []


def test_normalise_ignores_case_spacing_and_punctuation():
    assert bank_scan.normalise("Khas Stores") == bank_scan.normalise("khas  stores")
    assert bank_scan.normalise("U.S. Polo Assn.") == "uspoloassn"


def test_an_empty_listing_yields_nothing_rather_than_failing():
    assert bank_scan.parse_listing("") == []
    assert bank_scan.parse_listing("You are using an outdated browser.") == []
