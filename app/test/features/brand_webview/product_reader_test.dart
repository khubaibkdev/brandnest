import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/features/brand_webview/product_reader.dart';

void main() {
  group('buildReaderScript', () {
    test('embeds no pattern when the brand has none configured', () {
      final script = buildReaderScript(null);

      expect(script, contains('var productUrlPattern = null;'));
    });

    test('embeds the pattern as a RegExp constructor, not a /pattern/ literal', () {
      // A `/pattern/` literal would break on the unescaped slashes in a URL
      // path pattern — the constructor form sidesteps that entirely.
      final script = buildReaderScript('/products/[^/?#]+');

      expect(script, contains('new RegExp("/products/[^/?#]+")'));
    });
  });

  group('DetectedPage.fromJs', () {
    test('a product_view payload is a product', () {
      final page = DetectedPage.fromJs({
        'type': 'product_view',
        'url': 'https://example.pk/products/x',
        'title': 'A Shirt',
      });

      expect(page.isProduct, true);
      expect(page.url, 'https://example.pk/products/x');
      expect(page.title, 'A Shirt');
    });

    test('a page_view payload is not a product', () {
      final page = DetectedPage.fromJs({
        'type': 'page_view',
        'url': 'https://example.pk/',
      });

      expect(page.isProduct, false);
      expect(page.title, null);
    });
  });

  group('order confirmation (US-18)', () {
    test('embeds each configured pattern as a JSON string', () {
      final script = buildReaderScript(
        null,
        orderConfirmPatterns: [r'/thank[_-]you', r'/orders/[0-9a-f]{32}'],
      );

      expect(
        script,
        contains(r'var orderPatterns = ["/thank[_-]you","/orders/[0-9a-f]{32}"];'),
      );
    });

    test('a brand with no patterns gets an empty list, not a crash', () {
      final script = buildReaderScript('/products/x');

      expect(script, contains('var orderPatterns = [];'));
    });

    test('the order check runs before the product check', () {
      // A Shopify thank-you URL can sit under a path that also satisfies the
      // product pattern; whichever is tested first wins, and missing an order
      // costs the shopper points they earned.
      final script = buildReaderScript('/products/x', orderConfirmPatterns: [r'/thank_you']);

      expect(
        script.indexOf('isOrderPage()'),
        lessThan(script.indexOf('productUrlPattern.test')),
      );
    });

    test('a bad pattern is caught so the rest still run', () {
      final script = buildReaderScript(null, orderConfirmPatterns: [r'[unclosed']);

      expect(script, contains('catch (e)'));
    });

    test('an order_confirmed payload is an order and not a product', () {
      final page = DetectedPage.fromJs({
        'type': 'order_confirmed',
        'url': 'https://example.pk/checkouts/c/abc/thank_you',
      });

      expect(page.isOrderConfirmation, true);
      expect(page.isProduct, false);
    });

    test('an ordinary page is neither', () {
      final page = DetectedPage.fromJs({
        'type': 'page_view',
        'url': 'https://example.pk/collections/sale',
      });

      expect(page.isOrderConfirmation, false);
      expect(page.isProduct, false);
    });
  });
}
