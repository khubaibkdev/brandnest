"""Seed the brand table. Every entry is probe-verified: Shopify brands had an
open `products.json`, SFCC brands a readable sitemap (Sprint 1, and the D-4
wave on 2026-09-04)."""

from sqlalchemy import select

from app.db import get_session
from app.models import Brand, BrandConfig

# (slug, name, website_url, platform, is_active, products_json_ok, categories)
BRANDS = [
    # Active pilots — open Shopify products.json confirmed by probe
    ("outfitters", "Outfitters", "https://outfitters.com.pk", "shopify", True, True,
     ["women", "men", "kids"]),
    ("junaid-jamshed", "Junaid Jamshed (J.)", "https://www.junaidjamshed.com", "shopify",
     True, True, ["women", "men", "kids", "unstitched"]),
    ("bonanza-satrangi", "Bonanza Satrangi", "https://bonanzasatrangi.com", "shopify",
     True, True, ["women", "unstitched"]),
    ("limelight", "Limelight", "https://limelight.pk", "shopify", True, True,
     ["women", "unstitched", "accessories"]),
    ("alkaram-studio", "Alkaram Studio", "https://www.alkaramstudio.com", "shopify",
     True, True, ["women", "unstitched"]),
    # Next wave — Shopify confirmed, activate after pilot proves stable
    ("beechtree", "Beechtree", "https://beechtree.pk", "shopify", False, True, ["women"]),
    ("edenrobe", "Edenrobe", "https://www.edenrobe.com", "shopify", False, True,
     ["women", "men", "kids"]),
    ("zellbury", "Zellbury", "https://zellbury.com", "shopify", False, True,
     ["women", "men", "unstitched"]),
    # Salesforce Commerce Cloud. `www.khaadi.com` is a country splash page, not a
    # store — the Pakistani storefront is `pk.khaadi.com` (Sprint 18).
    ("khaadi", "Khaadi", "https://pk.khaadi.com", "salesforce_cc", True, False,
     ["women", "men", "kids", "unstitched"]),
    ("sapphire", "Sapphire", "https://pk.sapphireonline.pk", "salesforce_cc", True, False,
     ["women", "men", "kids", "unstitched"]),
    # D-4 wave — the 15 that take the catalog to 25. All probed 2026-09-04:
    # open `products.json`, parsed by the existing Shopify adapter.
    # `categories` drives the app's grid tabs and is a best-effort reading of
    # each brand's own navigation, not something the crawl can confirm.
    ("gul-ahmed", "Gul Ahmed", "https://www.gulahmedshop.com", "shopify", True, True,
     ["women", "men", "kids", "unstitched"]),
    ("nishat-linen", "Nishat Linen", "https://nishatlinen.com", "shopify", True, True,
     ["women", "men", "kids", "unstitched"]),
    ("sana-safinaz", "Sana Safinaz", "https://www.sanasafinaz.com", "shopify", True, True,
     ["women", "unstitched"]),
    ("maria-b", "Maria B", "https://www.mariab.pk", "shopify", True, True,
     ["women", "kids", "unstitched"]),
    ("chinyere", "Chinyere", "https://chinyere.pk", "shopify", True, True,
     ["women", "unstitched"]),
    ("cross-stitch", "Cross Stitch", "https://crossstitch.pk", "shopify", True, True,
     ["women", "unstitched"]),
    ("generation", "Generation", "https://generation.com.pk", "shopify", True, True,
     ["women", "unstitched"]),
    ("almirah", "Almirah", "https://almirah.com.pk", "shopify", True, True,
     ["women", "unstitched"]),
    ("asim-jofa", "Asim Jofa", "https://asimjofa.com", "shopify", True, True,
     ["women", "unstitched"]),
    ("breakout", "Breakout", "https://breakout.com.pk", "shopify", True, True,
     ["women", "men", "kids"]),
    # Ideas is not a separate store: `ideas.com.pk` redirects to
    # `gulahmedshop.com` and served the identical 8 products (found 2026-09-04).
    # Kept inactive so a reseed cannot recreate the duplicate.
    ("ideas", "Ideas", "https://www.ideas.com.pk", "shopify", False, True,
     ["women", "men", "kids", "unstitched"]),
    ("khas-stores", "Khas Stores", "https://khasstores.com", "shopify", True, True,
     ["women", "men", "kids", "unstitched"]),
    ("zeen", "Zeen", "https://zeenwoman.com", "shopify", True, True,
     ["women", "unstitched"]),
    ("saya", "Saya", "https://saya.pk", "shopify", True, True,
     ["women", "unstitched"]),
    ("diners", "Diners", "https://diners.com.pk", "shopify", True, True,
     ["men", "women"]),
    ("uniworth", "Uniworth", "https://uniworthshop.com", "shopify", True, True,
     ["men"]),
]

# Header logos taken from each brand's own Shopify CDN, sized to 512px wide. Shopify
# rasterises SVG sources when asked for `format=png`, which Flutter's Image.network needs.
# A brand with no entry here renders a monogram tile in the app.
LOGOS = {
    "outfitters":
        "https://outfitters.com.pk/cdn/shop/files/resize_otr_logo_jpg.jpg"
        "?v=1780894993&width=512",
    "junaid-jamshed":
        "https://www.junaidjamshed.com/cdn/shop/files/"
        "logo_black_-_wania_saleem_453f84ad-f61b-4978-ab3d-785cf12ce04c.svg"
        "?width=512&format=png",
    "bonanza-satrangi":
        "https://cdn.shopify.com/s/files/1/0619/9695/7785/files/Group_11.svg"
        "?width=512&format=png",
    "limelight":
        "https://limelight.pk/cdn/shop/files/"
        "LimeLight_New_Logo_Source_File-01_220x_60ba6562-d3a3-4362-83ec-25aeadc96177.svg"
        "?width=512&format=png",
    "alkaram-studio":
        "https://www.alkaramstudio.com/cdn/shop/files/700x105.png"
        "?v=1713331800&width=512",
    # D-4 wave, curated 2026-09-04 by eye against a contact sheet. Rejected on
    # sight: Almirah's and Beechtree's headers link Baadmay's logo (a payment
    # partner, not the brand); Chinyere's, Nishat's and Zellbury's og:image are
    # marketing banners; Cross Stitch's and Asim Jofa's header logos are white
    # and would vanish on the tile's white plate. Zellbury has no dark wordmark
    # anywhere, so its 512px favicon mark is used instead.
    "almirah":
        "https://almirah.com.pk/cdn/shop/files/"
        "Almirah_Logo-01_a883c537-fb07-4cda-b915-7eb0528785db.png?width=512",
    "asim-jofa":
        "https://asimjofa.com/cdn/shop/files/"
        "Asim_Jofa_8c4bc4c9-86dd-4be4-b0c0-cb93ba1352c4.png?width=512",
    "beechtree":
        "https://beechtree.pk/cdn/shop/files/"
        "thumb_2082914a-7cc9-4f2f-ba9e-b558fb264051.png?width=512",
    "breakout":
        "https://www.breakout.com.pk/cdn/shop/files/Bkt_logo.svg?width=512&format=png",
    "chinyere":
        "https://www.chinyere.pk/cdn/shop/files/"
        "chinyere-logo_1_4dac5727-89e6-4e26-93dc-68a733b26107.png?width=512",
    "cross-stitch":
        "https://www.crossstitch.pk/cdn/shop/files/"
        "cross-stitch-logo-black_300x300.png?width=512",
    "diners":
        "https://diners.com.pk/cdn/shop/files/"
        "web-logo_1_2_5599bf00-9ec0-48c5-8973-a3ef03dbb92b.png?width=512",
    "edenrobe":
        "https://edenrobe.com/cdn/shop/files/Edenrobe_Logo.jpg?width=512",
    "generation":
        "https://generation.com.pk/cdn/shop/files/"
        "logo2_e96bd3ec-e8c8-4de9-95e6-fe99304fd682.svg?width=512&format=png",
    # gulahmedshop.com is the "Gul Ahmed Ideas" store, so its own mark is the
    # Ideas one — see the `ideas` note in BRANDS.
    "gul-ahmed":
        "https://www.gulahmedshop.com/cdn/shop/files/Ideas_by_Gul_Ahmed_logo.png?width=512",
    # Salesforce Commerce Cloud: no `width`/`format` support on this path.
    "khaadi":
        "https://pk.khaadi.com/on/demandware.static/Sites-Khaadi_PK-Site/-/default/"
        "dwefec7a28/images/Khaadi-Logo-OG.png",
    "khas-stores":
        "https://www.khasstores.com/cdn/shop/files/"
        "KHAS_New_logo_200x100_desk_logo.webp?width=512&format=png",
    "maria-b":
        "https://www.mariab.pk/cdn/shop/files/bbb.png?width=512",
    "nishat-linen":
        "https://nishatlinen.com/cdn/shop/files/final_logo_1_nishat-golden.png?width=512",
    "sana-safinaz":
        "https://sanasafinaz.com/cdn/shop/files/Sana_Safinaz_1.png?width=512",
    # Not linked from any page (no og:image, no manifest) — the header itself is
    # an inline white SVG that would vanish on the tile's white plate — but this
    # PNG wordmark sits alongside it in the same demandware.static bucket,
    # found 2026-09-05 by probing common filenames.
    "sapphire":
        "https://pk.sapphireonline.pk/on/demandware.static/Sites-Sapphire-Site/-/default/"
        "dwbd0d5cef/images/sapphire-logo.png",
    "saya":
        "https://saya.pk/cdn/shop/files/SAYA-LOGO-SHOPIFY-STORE-BLACK.png?width=512",
    "uniworth":
        "https://uniworthshop.com/cdn/shop/files/"
        "Logo_Uniworth_navy-01.svg?width=512&format=png",
    "zeen":
        "https://zeenwoman.com/cdn/shop/files/Zeen_1_22.png?width=512",
    "zellbury":
        "https://zellbury.com/cdn/shop/files/Favicon-new.png?width=512",
}


def checkout_domains_for(platform: str) -> list[str]:
    """Hosts *other than the brand's own* that legitimately carry its checkout.

    Shopify's same-domain checkout (`brand.com/checkouts/...`) needs no entry: the
    address strip already shows the brand's own host, which is the reassurance the
    shopper needs. These are the hosts where it would otherwise look like the brand
    site handed them off to a stranger.
    """
    return ["shop.app", "pay.shopify.com", "checkout.shopify.com"] if platform == "shopify" else []


def seed() -> None:
    session = get_session()
    created = 0
    logos_updated = 0
    configs_updated = 0
    for slug, name, url, platform, is_active, products_json_ok, categories in BRANDS:
        exists = session.execute(select(Brand).where(Brand.slug == slug)).scalar_one_or_none()
        if exists:
            if slug in LOGOS and exists.logo_url != LOGOS[slug]:
                exists.logo_url = LOGOS[slug]
                logos_updated += 1
            if exists.config.checkout_domains != checkout_domains_for(platform):
                exists.config.checkout_domains = checkout_domains_for(platform)
                configs_updated += 1
            continue
        brand = Brand(
            slug=slug,
            name=name,
            website_url=url,
            logo_url=LOGOS.get(slug),
            platform=platform,
            is_active=is_active,
            categories=categories,
            priority_tier=1 if is_active else 2,
        )
        session.add(brand)
        session.flush()
        session.add(
            BrandConfig(
                brand_id=brand.id,
                products_json_ok=products_json_ok,
                checkout_domains=checkout_domains_for(platform),
            )
        )
        created += 1
    session.commit()
    session.close()
    print(
        f"seeded {created} new brands ({len(BRANDS) - created} already present); "
        f"{logos_updated} logos updated; {configs_updated} configs updated"
    )


if __name__ == "__main__":
    seed()
