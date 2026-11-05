"""US-3/US-5: the weekly scan of brand sites for announced bank discounts.

Precision matters more than recall here. A missed offer is caught by next
week's run or by a community report; a false one costs the desk a review and,
if waved through, puts an invented discount back in front of shoppers.
"""

import pytest
from sqlalchemy import select

from app.models import Bank, BankOffer, Brand
from app.services import offer_scan


@pytest.fixture
def banks(session):
    """The real seeded banks — the aliases under test are theirs."""
    rows = session.scalars(
        select(Bank).where(
            Bank.slug.in_(["ubl", "meezan", "bank-alfalah", "standard-chartered"])
        )
    ).all()
    assert rows, "banks are not seeded; run scripts.seed_bank_offers"
    return list(rows)


@pytest.fixture
def brand(session):
    brand = Brand(
        slug="test-scan-brand",
        name="Test Scan Brand",
        website_url="https://example.pk",
        platform="shopify",
        is_active=True,
        categories=["women"],
    )
    session.add(brand)
    session.flush()
    return brand


def test_a_real_announcement_is_found(banks):
    text = "Eid offer: get 15% off with your Meezan Bank debit card this week."

    found = offer_scan.find_offers(text, banks)

    assert [(bank.slug, pct) for bank, pct, _ in found] == [("meezan", 15)]


def test_a_short_form_the_copy_actually_uses_is_found(banks):
    """Retail copy writes "Alfalah", not "Bank Alfalah"."""
    text = "Flat 20% discount on Alfalah credit cards."

    found = offer_scan.find_offers(text, banks)

    assert [bank.slug for bank, _, _ in found] == ["bank-alfalah"]


def test_a_bank_name_inside_another_word_is_not_a_bank(banks):
    """"UBL" sits inside "DOUBLE" — this exact false positive turned up on a
    real brand site while looking for bank offers."""
    text = "BOYS STRIPED DOUBLE POCKET SHIRT now 30% off"

    assert offer_scan.find_offers(text, banks) == []


def test_fabric_composition_is_never_a_discount(banks):
    """Product pages say "100% cotton" constantly; three digits cannot match."""
    text = "100% cotton lawn, Meezan Bank stocked colours"

    assert offer_scan.find_offers(text, banks) == []


def test_a_brand_sale_with_no_bank_named_is_not_a_bank_offer(banks):
    text = "END OF SEASON SALE — FLAT 50% OFF EVERYTHING"

    assert offer_scan.find_offers(text, banks) == []


def test_a_percentage_far_from_the_bank_name_is_not_related(banks):
    filler = "x" * (offer_scan.PROXIMITY_CHARS + 50)
    text = f"Meezan Bank branchless banking {filler} unrelated 25% off sale"

    assert offer_scan.find_offers(text, banks) == []


def test_an_implausible_percentage_is_ignored(banks):
    """A 95% discount is a typo or a countdown, not a bank offer."""
    text = "Meezan Bank customers save 95% today"

    assert offer_scan.find_offers(text, banks) == []


def test_the_snippet_records_what_was_read(banks):
    text = "Enjoy 15% off with Meezan Bank cards"

    _, _, snippet = offer_scan.find_offers(text, banks)[0]

    assert "Meezan Bank" in snippet


def test_a_found_offer_is_filed_unverified_with_its_proof(session, banks, brand, monkeypatch):
    monkeypatch.setattr(
        offer_scan,
        "pages_to_scan",
        lambda b, f: [("https://example.pk/offers", "Get 15% off with Meezan Bank cards")],
    )

    filed = offer_scan.scan_brand(session, brand, banks, fetcher=None)

    assert filed == 1
    offer = session.scalar(select(BankOffer).where(BankOffer.brand_id == brand.id))
    assert offer.status == "needs_verification"
    assert offer.source == "auto-scan"
    assert offer.proof_url == "https://example.pk/offers"
    assert offer.verified_by is None


def test_the_same_offer_next_week_is_not_filed_twice(session, banks, brand, monkeypatch):
    monkeypatch.setattr(
        offer_scan,
        "pages_to_scan",
        lambda b, f: [("https://example.pk/offers", "Get 15% off with Meezan Bank cards")],
    )
    offer_scan.scan_brand(session, brand, banks, fetcher=None)

    assert offer_scan.scan_brand(session, brand, banks, fetcher=None) == 0


def test_an_offer_the_desk_rejected_does_not_come_back(session, banks, brand, monkeypatch):
    """Re-filing something a human already threw out would make the queue
    impossible to keep clear."""
    monkeypatch.setattr(
        offer_scan,
        "pages_to_scan",
        lambda b, f: [("https://example.pk/offers", "Get 15% off with Meezan Bank cards")],
    )
    offer_scan.scan_brand(session, brand, banks, fetcher=None)
    offer = session.scalar(select(BankOffer).where(BankOffer.brand_id == brand.id))
    offer.status = "rejected"
    session.flush()

    assert offer_scan.scan_brand(session, brand, banks, fetcher=None) == 0


def test_an_unreadable_homepage_skips_the_brand_rather_than_failing(brand):
    class Failing:
        def get_html(self, url):
            raise RuntimeError("blocked")

    assert offer_scan.pages_to_scan(brand, Failing()) == []


class _RecordingFetcher:
    """Serves one homepage and records every follow-up URL requested."""

    def __init__(self, homepage_html: str):
        self.homepage_html = homepage_html
        self.requested: list[str] = []

    def get_html(self, url):
        self.requested.append(url)
        if len(self.requested) == 1:
            return self.homepage_html, "https://example.pk/"
        return "<html></html>", url


def test_a_protocol_relative_link_keeps_its_own_host(brand):
    """`//host/path` pasted onto our host produced `example.pk/example.pk/...`
    404s on the first live run."""
    fetcher = _RecordingFetcher('<a href="//cdn.example.pk/pages/bank-offers">Offers</a>')

    offer_scan.pages_to_scan(brand, fetcher)

    assert fetcher.requested[1] == "https://cdn.example.pk/pages/bank-offers"


def test_a_relative_link_resolves_against_the_page(brand):
    fetcher = _RecordingFetcher('<a href="/pages/offers">Offers</a>')

    offer_scan.pages_to_scan(brand, fetcher)

    assert fetcher.requested[1] == "https://example.pk/pages/offers"


def test_theme_assets_matching_the_keyword_are_not_fetched(brand):
    """`component-discounts.css` matches "discount" and is never an
    announcement — four were fetched before this guard existed."""
    fetcher = _RecordingFetcher(
        '<a href="/assets/component-discounts.css">x</a>'
        '<a href="/pages/offers">Offers</a>'
    )

    offer_scan.pages_to_scan(brand, fetcher)

    assert all(".css" not in url for url in fetcher.requested)
    assert fetcher.requested[1] == "https://example.pk/pages/offers"

