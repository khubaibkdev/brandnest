import 'dart:convert';

/// Read-only injected script (US-13, ARCHITECTURE.md §6). It never mutates
/// the DOM — only `location.href` and a couple of `<meta>` tags.
///
/// `og:type`/`og:url`/`og:title` are the source, not JSON-LD `Product`
/// schema — real storefront themes sampled across our brands don't
/// consistently emit Product schema, but every one sets these OpenGraph tags
/// correctly, since they're what makes a shared product link look right.
///
/// `productUrlRegex` is `brand_config`'s cheap pre-filter: reject obviously
/// non-product pages by URL before touching the DOM at all, as
/// CRAWLER_PLAYBOOK's "cheap product-page detection before metadata parses"
/// describes. `RegExp(pattern)` (constructor form, not a `/pattern/`
/// literal) sidesteps having to escape the `/` characters a URL path pattern
/// is full of.
String buildReaderScript(
  String? productUrlRegex, {
  List<String> orderConfirmPatterns = const [],
}) {
  final pattern = productUrlRegex == null
      ? 'null'
      : 'new RegExp(${jsonEncode(productUrlRegex)})';
  final orderPatterns = orderConfirmPatterns.map(jsonEncode).join(',');
  return '''
(function() {
  var productUrlPattern = $pattern;
  var orderPatterns = [$orderPatterns];
  function isOrderPage() {
    for (var i = 0; i < orderPatterns.length; i++) {
      try {
        if (new RegExp(orderPatterns[i]).test(location.href)) return true;
      } catch (e) { /* a bad pattern must not break the rest */ }
    }
    return false;
  }
  function readPage() {
    // Checked first: a thank-you page is neither a product nor an ordinary
    // page, and missing it costs the shopper points they earned.
    if (isOrderPage()) {
      return { type: 'order_confirmed', url: location.href };
    }
    if (productUrlPattern && !productUrlPattern.test(location.href)) {
      return { type: 'page_view', url: location.href };
    }
    var ogType = document.querySelector('meta[property="og:type"]');
    if (!ogType || ogType.content !== 'product') {
      return { type: 'page_view', url: location.href };
    }
    var ogUrl = document.querySelector('meta[property="og:url"]');
    var ogTitle = document.querySelector('meta[property="og:title"]');
    // Image and price are only a snapshot for pinning a page we have not
    // crawled (US-21); a crawled product's own catalog data wins.
    var ogImage = document.querySelector('meta[property="og:image"]');
    var ogPrice = document.querySelector(
      'meta[property="og:price:amount"], meta[property="product:price:amount"]');
    return {
      type: 'product_view',
      url: (ogUrl && ogUrl.content) || location.href,
      title: (ogTitle && ogTitle.content) || document.title,
      image: ogImage && ogImage.content,
      price: ogPrice && ogPrice.content,
    };
  }
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler('brandnest', readPage());
  }
})();
''';
}

/// What the reader script reported for the page currently on screen.
class DetectedPage {
  const DetectedPage({
    required this.isProduct,
    required this.url,
    this.title,
    this.imageUrl,
    this.price,
    this.isOrderConfirmation = false,
  });

  final bool isProduct;
  final String url;
  final String? title;
  final String? imageUrl;

  /// As the page states it, e.g. "12,990.00" — kept as text and sent on as-is.
  final String? price;

  /// The shopper just completed an order here (US-18).
  final bool isOrderConfirmation;

  static const none = DetectedPage(isProduct: false, url: '');

  factory DetectedPage.fromJs(Map<String, dynamic> payload) => DetectedPage(
    isProduct: payload['type'] == 'product_view',
    isOrderConfirmation: payload['type'] == 'order_confirmed',
    url: payload['url'] as String? ?? '',
    title: payload['title'] as String?,
    imageUrl: payload['image'] as String?,
    price: payload['price'] as String?,
  );
}
