"""US-8: the Salesforce Commerce Cloud adapter. Scraping a real e-commerce
site's HTML is inherently more fragile than Shopify's JSON feed, so these pin
the parsing behaviour against realistic fixture pages rather than trusting it
to only be exercised live."""

from decimal import Decimal

from app.crawlers.sitemap_html import _parse_product_page

URL = "https://pk.sapphireonline.pk/collections/ready-to-wear/products/ABC123.html"


def _page(
    data_layer: str,
    notify_me: str = '<div class="notifyMe-wrapper d-none">',
    gallery: str = "",
) -> str:
    return f"""
    <html><body>
    <script>
        var dataLayerEvent = {data_layer};
    </script>
    {notify_me}
    {gallery}
    </body></html>
    """


# Shaped like the real markup: the browser-visible `src` is a base64 placeholder
# until the lazyload script runs, and the real file is in `data-high-src`.
def _pdp_image(filename: str) -> str:
    return (
        '<img width="auto" height="auto" '
        f'data-high-src="https://pk.sapphireonline.pk/dw/image/v2/X/{filename}" '
        'src="data:image/png;base64,iVBORw0KGgo=" '
        f'data-src="https://pk.sapphireonline.pk/dw/image/v2/X/{filename}?sw=1000&amp;sh=1200" '
        'class="d-block pdp-image lazyload" alt="X">'
    )


DATA_LAYER = (
    '{"ecommerce":{"detail":{"products":'
    '[{"id":"ABC123","name":"X","price":"1490.00","compare_price":1490}]}}}'
)


def test_a_normal_product_parses_price_title_and_category():
    html = _page(
        '{"event":"pdp","ecommerce":{"detail":{"products":'
        '[{"id":"ABC123","name":"Printed Voile Dupatta","category":"Ready to Wear",'
        '"price":"2290.00","compare_price":2290}]}}}'
    )

    product = _parse_product_page(html, URL)

    assert product.external_id == "ABC123"
    assert product.title == "Printed Voile Dupatta"
    assert product.category == "Ready to Wear"
    assert product.source_url == URL
    variant = product.variants[0]
    assert variant.external_id == "ABC123"
    assert variant.price == Decimal("2290.00")


def test_compare_price_equal_to_price_is_not_a_real_discount():
    """SFCC's tracking blob carries `compare_price` on every product, sale or
    not — only a genuine markdown should read as one."""
    html = _page(
        '{"ecommerce":{"detail":{"products":'
        '[{"id":"ABC123","name":"X","price":"1490.00","compare_price":1490}]}}}'
    )

    product = _parse_product_page(html, URL)

    assert product.variants[0].compare_at_price is None


def test_a_genuine_markdown_keeps_its_compare_price():
    html = _page(
        '{"ecommerce":{"detail":{"products":'
        '[{"id":"ABC123","name":"X","price":"1490.00","compare_price":1990}]}}}'
    )

    product = _parse_product_page(html, URL)

    assert product.variants[0].compare_at_price == Decimal("1990")


def test_a_visible_notify_me_button_means_out_of_stock():
    html = _page(
        '{"ecommerce":{"detail":{"products":[{"id":"ABC123","name":"X","price":"100"}]}}}',
        notify_me='<div class="notifyMe-wrapper">',
    )

    product = _parse_product_page(html, URL)

    assert product.variants[0].in_stock is False


def test_no_notify_me_element_at_all_defaults_to_in_stock():
    html = _page(
        '{"ecommerce":{"detail":{"products":[{"id":"ABC123","name":"X","price":"100"}]}}}',
        notify_me="",
    )

    product = _parse_product_page(html, URL)

    assert product.variants[0].in_stock is True


def test_a_redirect_away_from_the_product_page_means_delisted():
    """SFCC bounces a dead product back to its collection page. That page's
    tracking blob is the real signal — it carries `impressions` and no
    `detail`, so there is no product to read. Verified against the live
    redirect for a delisted Sapphire product on 2026-09-03."""
    html = _page('{"event":"search","ecommerce":{"impressions":[]}}')

    product = _parse_product_page(html, "https://pk.sapphireonline.pk/collections/ready-to-wear")

    assert product is None


def test_a_page_with_no_tracking_data_is_skipped_not_crashed():
    assert _parse_product_page("<html><body>nothing here</body></html>", URL) is None


def test_malformed_tracking_json_is_skipped_not_crashed():
    html = _page("{not valid json")

    assert _parse_product_page(html, URL) is None


def test_gallery_images_are_captured_in_order():
    html = _page(
        DATA_LAYER,
        gallery=_pdp_image("ABC123_2.JPG") + _pdp_image("ABC123_3.JPG"),
    )

    product = _parse_product_page(html, URL)

    assert product.image_urls == [
        "https://pk.sapphireonline.pk/dw/image/v2/X/ABC123_2.JPG",
        "https://pk.sapphireonline.pk/dw/image/v2/X/ABC123_3.JPG",
    ]


def test_the_base64_placeholder_src_is_never_captured():
    """`src` holds an inline base64 pixel until JavaScript swaps it; storing
    that would give every product the same non-image."""
    html = _page(DATA_LAYER, gallery=_pdp_image("ABC123_2.JPG"))

    product = _parse_product_page(html, URL)

    assert all(url.startswith("https://") for url in product.image_urls)


def test_images_outside_the_pdp_gallery_are_ignored():
    """A recommendation carousel is another product's photos — attaching them
    here would show the wrong picture."""
    other = (
        '<img data-high-src="https://pk.sapphireonline.pk/dw/image/v2/X/OTHER_1.JPG" '
        'class="recommendation-tile">'
    )
    html = _page(DATA_LAYER, gallery=_pdp_image("ABC123_2.JPG") + other)

    product = _parse_product_page(html, URL)

    assert product.image_urls == ["https://pk.sapphireonline.pk/dw/image/v2/X/ABC123_2.JPG"]


def test_a_product_with_no_gallery_images_parses_with_an_empty_list():
    product = _parse_product_page(_page(DATA_LAYER), URL)

    assert product.image_urls == []


def _ld_json(images: str) -> str:
    return (
        '<script type="application/ld+json">'
        '{"@context":"http://schema.org/","@type":"Product","name":"X",'
        f'"sku":"ABC123","image":{images}}}'
        "</script>"
    )


def test_schema_org_product_images_are_preferred_over_the_lazy_gallery():
    """Khaadi publishes its images as schema.org Product data — the site
    stating its own product data beats markup we inferred."""
    html = _page(
        DATA_LAYER,
        gallery=_ld_json('["/images/a.jpg","/images/b.jpg"]')
        + _pdp_image("ABC123_2.JPG"),
    )

    product = _parse_product_page(html, URL)

    assert product.image_urls == [
        "https://pk.sapphireonline.pk/images/a.jpg",
        "https://pk.sapphireonline.pk/images/b.jpg",
    ]


def test_relative_image_paths_are_resolved_against_the_page():
    """Khaadi's JSON-LD carries site-relative paths; stored as-is they would
    not load anywhere."""
    html = _page(DATA_LAYER, gallery=_ld_json('["/on/demandware.static/x.jpg"]'))

    product = _parse_product_page(html, URL)

    assert product.image_urls == ["https://pk.sapphireonline.pk/on/demandware.static/x.jpg"]


def test_a_non_product_json_ld_block_is_not_mistaken_for_the_gallery():
    """Sapphire publishes Organization and ClothingStore blocks, the latter
    carrying an `image` — its logo, not the product."""
    store = (
        '<script type="application/ld+json">'
        '{"@type":"ClothingStore","image":"/logo.png"}</script>'
    )
    html = _page(DATA_LAYER, gallery=store + _pdp_image("ABC123_2.JPG"))

    product = _parse_product_page(html, URL)

    assert product.image_urls == ["https://pk.sapphireonline.pk/dw/image/v2/X/ABC123_2.JPG"]


def test_malformed_json_ld_falls_back_to_the_gallery():
    broken = '<script type="application/ld+json">{not json}</script>'
    html = _page(DATA_LAYER, gallery=broken + _pdp_image("ABC123_2.JPG"))

    product = _parse_product_page(html, URL)

    assert product.image_urls == ["https://pk.sapphireonline.pk/dw/image/v2/X/ABC123_2.JPG"]
