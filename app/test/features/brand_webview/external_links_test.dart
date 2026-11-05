import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/features/brand_webview/external_links.dart';

void main() {
  test('the WebView keeps what it can render itself', () {
    expect(opensInAnotherApp(Uri.parse('https://outfitters.com.pk')), isFalse);
    expect(opensInAnotherApp(Uri.parse('http://outfitters.com.pk')), isFalse);
    expect(opensInAnotherApp(Uri.parse('about:blank')), isFalse);
  });

  test('links belonging to other apps are handed to the OS', () {
    expect(opensInAnotherApp(Uri.parse('whatsapp://send?phone=923001')), isTrue);
    expect(opensInAnotherApp(Uri.parse('tel:+922135678901')), isTrue);
    expect(opensInAnotherApp(Uri.parse('mailto:help@outfitters.com.pk')), isTrue);
    expect(
      opensInAnotherApp(Uri.parse('intent://pay#Intent;scheme=upi;end')),
      isTrue,
    );
  });
}
