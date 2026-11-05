"""US-11: the canonical category and audience a shopper filters by.

Every case here is a real (title, category) pair from the crawled catalog, not
an invented one — most of them are pairs that were classified *wrongly* by an
earlier version of the rules.
"""

import pytest

from app.services.categories import classify


@pytest.mark.parametrize(
    "title,raw,expected",
    [
        # The pair that forces reading the title: Junaid Jamshed files both
        # under `3 Piece`, and unstitched-vs-stitched is the whole distinction.
        ("BLUE LAWN EMBROIDERED UNSTITCHED 3PC", "3 Piece", "Unstitched Fabric"),
        ("BLACK DOBBY EMBROIDERED 3PC STITCHED", "3 Piece", "Ready to Wear"),
        # Fabric state beats the garments named in the set.
        ("Shirt Shalwar Dupatta - 0891", "Essential Unstitched", "Unstitched Fabric"),
        # ...and a stitched set is the set, not any one garment in it.
        ("Kurta Dupatta Trouser - 1216", "Essential Pret", "Ready to Wear"),
        ("Kurta Trouser - 2463", "Essential Pret", "Ready to Wear"),
        ("OFF WHITE BLENDED KAMEEZ SHALWAR", "Kameez Shalwar", "Ready to Wear"),
        # A lone dupatta really is a dupatta.
        ("BLACK JACQUARD DYED DUPATTA", "Dupatta", "Dupatta & Shawls"),
        ("Viscose Scarf", "Head wear", "Dupatta & Shawls"),
        # Garments that stand alone.
        ("TEA PINK COTTON CASUAL SHORT KURTA", "Kurta", "Kurta & Kurti"),
        ("Barrel Fit Pants", "TROUSERS", "Bottoms"),
        ("Color Block Slogan Print T-Shirt", "TEES", "Shirts & Tops"),
        ("Denim Jacket With Hood", "JACKET", "Outerwear"),
        # Non-apparel, which must never be reached by a garment rule.
        ("Cross-Body Bags - E639", None, "Bags"),
        ("Wavy Circle Earrings", "Jewelry", "Jewellery"),
        ("BLACK TRENDY PESHAWARI SANDALS", "Peshawari Chappal", "Footwear"),
        ("Enigma 90ML", "Woman Body Mist Fragrance", "Fragrance & Beauty"),
        ("HOME | BEDSHEET SET", "BEDSHEET", "Home & Living"),
        ("Baseball Cap - 5020", "Caps", "Accessories"),
        # A brand that merchandises by style names no garment at all.
        ("JLAWN-S-21-327 Pinkish", "Essential Pret", "Ready to Wear"),
    ],
)
def test_classifies_real_catalog_products(title, raw, expected):
    assert classify(title, raw).category == expected


def test_a_plural_still_matches_its_keyword():
    """"bag" has to answer for "Bags" and "unstitch" for "Unstitched", or 7% of
    the catalog falls through to Other."""
    assert classify("Canvas Bag", "Canvas Bags").category == "Bags"
    assert classify("Lawn Suit", "Unstitched").category == "Unstitched Fabric"


def test_a_keyword_never_matches_a_longer_word():
    """The boundary rules that keep the tail honest: "ring" must not answer for
    "earring", and "bag" must not answer for "baggy"."""
    assert classify("Gold Earrings", "Jewelry").category == "Jewellery"
    assert classify("Baggy Fit Jeans", "JEANS").category == "Bottoms"
    assert classify("Capri Trousers", "TROUSERS").category == "Bottoms"


@pytest.mark.parametrize(
    "title,raw,expected",
    [
        ("Cotton Kurta - EMTK18S-9638", "Men Kurta", "Men"),
        ("Printed Cambric Shirt", "Girls Eastern", "Girls"),
        ("Full Sleeves Graphic Tee", "Boys T-Shirts", "Boys"),
        ("Printed Lawn Suit", "Woman Un Stitched", "Women"),
        ("GREY JACQUARD TEENS 3PC", "3 Piece", "Kids"),
    ],
)
def test_derives_the_audience_the_crawler_never_recorded(title, raw, expected):
    """`product.gender` is NULL on all 81k rows; the same text says it out loud."""
    assert classify(title, raw).audience == expected


def test_women_is_not_read_as_men():
    """Without a leading word boundary, "women" contains "men" and every
    women's product files itself under Men."""
    assert classify("Printed Lawn Shirt", "Woman Pret Printed").audience == "Women"
    assert classify("Formal Pants", "Men Formal Pants").audience == "Men"


def test_an_unrecognisable_product_is_not_forced_into_a_category():
    assert classify("JJKS-A-36753", None).category == "Other"


def test_tags_can_classify_but_never_make_a_set():
    """Tags help a product with a bare SKU title, but two garment words among
    dozens of tags must not turn a kurta into a suit."""
    assert classify("JJ-1234", None, ["kurta", "cotton"]).category == "Kurta & Kurti"
    assert (
        classify("JJ-1234", "Kurta", ["kurta", "shalwar", "dupatta"]).category
        == "Kurta & Kurti"
    )
