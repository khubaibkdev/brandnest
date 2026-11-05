import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/brand_config.dart';

void main() {
  test('parses a brand config payload', () {
    final config = BrandConfig.fromJson({
      'webview_user_agent': null,
      'checkout_domains': ['shop.app', 'pay.shopify.com'],
    });

    expect(config.webviewUserAgent, isNull);
    expect(config.checkoutDomains, ['shop.app', 'pay.shopify.com']);
  });

  test('an unknown brand surfaces as an error, not a silent empty config', () {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('{}', 404)),
    );

    expect(() => client.fetchBrandConfig('nope'), throwsException);
  });

  group('order confirmation patterns (US-18)', () {
    test('parses the patterns the server sends', () {
      final config = BrandConfig.fromJson({
        'webview_user_agent': null,
        'checkout_domains': <String>[],
        'product_url_regex': null,
        'order_confirm_patterns': [r'/thank[_-]you'],
      });

      expect(config.orderConfirmPatterns, [r'/thank[_-]you']);
    });

    test('an older API without the field yields no patterns, not a crash', () {
      final config = BrandConfig.fromJson({
        'webview_user_agent': null,
        'checkout_domains': <String>[],
        'product_url_regex': null,
      });

      expect(config.orderConfirmPatterns, isEmpty);
    });
  });
}
