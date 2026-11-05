"""US-11: turning 423 brand-specific category strings into filters a shopper can use.

Every brand names its own shelves ("Woman Un Stitched Allure Khaddar", "BTK-EAST",
"Essential Pret"), so the raw `product.category` is unusable as a facet across
brands — but it is exactly the detail someone wants once they have drilled in.
So both survive: the canonical category below is what the filter offers, and the
brand's own string rides along on every result underneath it.

Two things forced the shape of this:

* The raw category is not sufficient on its own. Junaid Jamshed files both
  "SKY BLUE LAWN UNSTITCHED 3PC" and "GREEN JACQUARD EMBROIDERED 3PC STITCHED"
  under `3 Piece`, and unstitched-vs-stitched is the single biggest thing a
  shopper here filters on. The title has to be read too.
* `product.gender` is NULL on every row the crawler has ever written, but the
  same text says "Men Kurta" and "Girls Frocks" out loud. Audience is derived
  here rather than left as a filter we cannot offer.
"""

import re
from dataclasses import dataclass

OTHER = "Other"
READY_TO_WEAR = "Ready to Wear"

# Marks where the "two garments means a set" test runs in the ordered rules —
# it needs the title alone, so it cannot be written as another keyword list.
_SET_SENTINEL = "<several garments>"

# The components a stitched eastern set is named after, grouped so that words
# for the *same* garment count once. Without the grouping "Barrel Fit Pants"
# filed under `TROUSERS` reads as two garments and becomes a suit.
GARMENT_GROUPS: tuple[tuple[str, ...], ...] = (
    ("kurta", "kurti", "kameez", "shirt"),
    ("shalwar", "trouser", "pant", "pajama", "pyjama", "culotte"),
    ("dupatta", "dupata"),
)

# Ready-to-wear that the garment count cannot see: a set named by its piece
# count ("3 Piece"), or a single stitched garment ("Frock", "Sherwani").
READY_TO_WEAR_PHRASES = (
    "co ord", "co-ord", "coord", "3 piece", "2 piece", "1 piece",
    "3pc", "2pc", "1pc", "suit", "sherwani", "frock", "dress", "gown",
    "abaya", "jumpsuit", "gharara", "sharara", "lehenga", "saree", "sari",
    "peshwas", "maxi", "dungaree",
)

# Ordered: the first rule that matches wins, so the specific sits above the
# general. Sets ("kameez shalwar", "3 piece") deliberately precede the garments
# they contain, or every two-piece suit would file itself under Kurta.
CATEGORY_RULES: list[tuple[str, tuple[str, ...]]] = [
    ("Footwear", (
        "khussa", "chappal", "peshawari", "shoe", "sneaker", "sandal", "heel",
        "loafer", "boot", "slipper", "pump", "kolapuri", "slide",
    )),
    ("Jewellery", (
        "jewel", "earring", "necklace", "bangle", "bracelet", "anklet",
        "brooch", "pendant", "ring", "jewelry", "jewellery",
    )),
    ("Bags", (
        "bag", "clutch", "wallet", "tote", "pouch", "purse", "backpack",
        "card holder",
    )),
    ("Fragrance & Beauty", (
        "fragrance", "perfume", "cologne", "beauty", "cosmetic", "makeup",
        "lipstick", "attar", "deodorant", "body spray", "body mist",
        "skin care", "skincare", "lotion",
    )),
    ("Home & Living", (
        "towel", "bedsheet", "bed sheet", "cushion", "blanket", "quilt",
        "home", "duvet", "bath sheet", "napkin",
    )),
    # Before any garment rule: "unstitched" changes what the thing *is*, not
    # merely how it is described. Zellbury's "Shirt Shalwar Dupatta" under
    # `Essential Unstitched` is fabric for a three-piece, not a dupatta — read
    # the other way round it lands in Dupatta & Shawls, which is why this sits
    # above that rule rather than below it.
    ("Unstitched Fabric", (
        "unstitch", "un stitched", "unstiched", "fabric", "yardage",
    )),
    # Sets before their parts, for the same reason: the garment words in
    # "Kameez Shalwar" or "Shirt Shalwar Dupatta" name what is *in* the set.
    (_SET_SENTINEL, ()),
    ("Dupatta & Shawls", (
        "dupatta", "dupata", "shawl", "stole", "scarf", "scarve", "scarfs",
        "chador", "hijab", "muffler", "shemagh",
    )),
    ("Accessories", (
        "cap", "caps", "hat", "head wear", "headwear", "belt", "sunglass",
        "sock", "tie", "glove", "underwear", "brace", "keychain", "watch",
        "boxer", "brief", "gift box",
        "accessory", "accessories",
    )),
    ("Outerwear", (
        "sweater", "hoodie", "sweatshirt", "sweat shirt", "jacket", "blazer",
        "coat", "waistcoat", "waist coat", "cardigan", "outerwear", "shrug",
        "poncho", "puffer",
    )),
    ("Kurta & Kurti", ("kurta", "kurti", "kameez", "jubba", "tunic", "eastern top")),
    ("Shirts & Tops", (
        "shirt", "tee", "tees", "t shirt", "polo", "blouse", "top", "tops",
        "tank", "vest", "high neck",
    )),
    ("Bottoms", (
        "shalwar", "trouser", "pant", "jean", "chino", "short", "culotte",
        "tight", "legging", "lower", "bottom", "pajama", "denim", "skirt",
        "capri", "palazzo",
    )),
    # The catch-all for a brand that merchandises by style, not by garment:
    # "Essential Pret", "RTW Luxury", "PRET" name no item at all.
    (READY_TO_WEAR, ("pret", "rtw", "ready to wear", "stitched", "western")),
]

# Girls/Boys before Women/Men: a brand writes "Girls Eastern", never
# "Women Girls", so the narrower audience is the true one when both appear.
AUDIENCE_RULES: list[tuple[str, tuple[str, ...]]] = [
    ("Girls", ("girl", "girls")),
    ("Boys", ("boy", "boys")),
    ("Kids", ("kid", "kids", "teen", "teens", "infant", "toddler", "baby", "junior")),
    ("Women", ("woman", "women", "womens", "ladies", "female", "ladie")),
    ("Men", ("man", "men", "mens", "gents", "male", "gent")),
]


@dataclass(frozen=True)
class Classification:
    category: str
    audience: str | None


def classify(
    title: str | None, raw_category: str | None, tags: list[str] | None = None
) -> Classification:
    """The canonical category and audience for one product.

    Title first in the haystack because it is where the decisive words live —
    a brand's shelf name is often only a merchandising label.
    """
    named = _normalize(" ".join(filter(None, [title, raw_category])))
    with_tags = _normalize(" ".join(filter(None, [named, *(tags or [])])))
    return Classification(
        category=_fall_back_to_tags(_category, named, with_tags) or OTHER,
        audience=_fall_back_to_tags(_audience, named, with_tags),
    )


def _fall_back_to_tags(read, named: str, with_tags: str) -> str | None:
    """Tags are a last resort, never a peer of the title.

    Plenty of products are titled with a bare SKU ("JJKS-A-36753"), and their
    tags are the only thing that says what they are. But a product carries
    dozens of tags, so letting them vote alongside the title lets one stray
    "dupatta" tag file a kurta under Dupatta & Shawls. So: read the title and
    the brand's category, and only reach for tags when they said nothing.
    """
    return read(named) or (read(with_tags) if with_tags != named else None)


def _category(text: str) -> str | None:
    """Rules in order, with one test that no keyword list can express sitting
    between the fabric-state rules and the garment rules."""
    for name, keywords in CATEGORY_RULES:
        if name == _SET_SENTINEL:
            if _is_ready_to_wear_item(text):
                return READY_TO_WEAR
            continue
        if any(_contains_phrase(text, keyword) for keyword in keywords):
            return name
    return None


def _audience(text: str) -> str | None:
    return _first_match(text, AUDIENCE_RULES)


def _is_ready_to_wear_item(named: str) -> bool:
    """A stitched set, or a ready-to-wear garment that stands on its own.

    Two *different* garments named together means the product is the set, not
    any one of them — Zellbury alone ships "Shirt Shalwar Dupatta", "Kurta
    Dupatta Trouser" and "Kurta Trouser", and enumerating those pairs never
    finishes.

    Reads only the title and the brand's own category, never the tags. A
    product carries dozens of tags, and letting "suit" or a second garment word
    among them decide would turn every kurta with a matching-trouser tag into a
    suit.
    """
    if any(_contains_phrase(named, phrase) for phrase in READY_TO_WEAR_PHRASES):
        return True
    return sum(_mentions_group(named, group) for group in GARMENT_GROUPS) >= 2


def _mentions_group(named: str, group: tuple[str, ...]) -> bool:
    return any(_contains_phrase(named, word) for word in group)


def _first_match(
    haystack: str, rules: list[tuple[str, tuple[str, ...]]]
) -> str | None:
    for name, keywords in rules:
        if any(_contains_phrase(haystack, keyword) for keyword in keywords):
            return name
    return None


def _contains_phrase(haystack: str, phrase: str) -> bool:
    """Whole words, plus the plain English endings, so one keyword covers
    "bag"/"bags" and "unstitch"/"unstitched".

    The *leading* boundary is the load-bearing half: without it "ring" answers
    for "earring" and "men" for "women", filing products under the wrong
    filter. The trailing side allows only s/es/ed rather than any suffix,
    which is what keeps "bag" off "baggy jeans" and "cap" off "capri".
    """
    return (
        re.search(rf"(?<![a-z0-9]){re.escape(phrase)}(?:e?s|ed)?(?![a-z0-9])", haystack)
        is not None
    )


def _normalize(text: str) -> str:
    """Lowercase, punctuation to spaces, runs collapsed — so "Un-Stitched",
    "UN STITCHED" and "un stitched" all reach the same rule."""
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9]+", " ", text.lower())).strip()
