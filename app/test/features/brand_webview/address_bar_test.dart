import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/features/brand_webview/address_bar.dart';

const _checkoutDomains = ['shop.app', 'pay.shopify.com'];

AddressBarState _stateFor(String url) =>
    AddressBarState.forUrl(Uri.parse(url), _checkoutDomains);

void main() {
  group('AddressBarState', () {
    test('shows host and padlock while browsing the brand', () {
      final state = _stateFor('https://outfitters.com.pk/collections/men');

      expect(state.host, 'outfitters.com.pk');
      expect(state.isSecure, isTrue);
      expect(state.isBrandCheckout, isFalse);
    });

    test('leaves same-domain Shopify checkout plain — the host is the proof', () {
      final state = _stateFor('https://outfitters.com.pk/checkouts/cn/abc123');

      expect(state.host, 'outfitters.com.pk');
      expect(state.isBrandCheckout, isFalse);
    });

    test('explains a hand-off to a third-party payment host', () {
      expect(_stateFor('https://shop.app/pay/xyz').isBrandCheckout, isTrue);
    });

    test('accepts subdomains of a payment host', () {
      expect(
        _stateFor('https://checkout.pay.shopify.com/c/1').isBrandCheckout,
        isTrue,
      );
    });

    test('is not fooled by a lookalike domain', () {
      expect(_stateFor('https://notshop.app/pay').isBrandCheckout, isFalse);
    });

    test('drops the padlock on plain http', () {
      expect(_stateFor('http://outfitters.com.pk').isSecure, isFalse);
    });
  });

  testWidgets('names the brand while on its third-party checkout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddressBar(
          state: _stateFor('https://shop.app/pay/xyz'),
          brandName: 'Outfitters',
          onClose: () {},
        ),
      ),
    );

    expect(find.text('shop.app'), findsOneWidget);
    expect(
      find.text('Paying securely on the official Outfitters checkout'),
      findsOneWidget,
    );
  });

  testWidgets('shows the host alone on the brand\'s own pages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddressBar(
          state: _stateFor('https://outfitters.com.pk/products/kurta'),
          brandName: 'Outfitters',
          onClose: () {},
        ),
      ),
    );

    expect(find.text('outfitters.com.pk'), findsOneWidget);
    expect(find.textContaining('Paying securely'), findsNothing);
  });
}
