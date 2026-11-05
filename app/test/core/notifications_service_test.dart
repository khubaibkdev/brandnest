import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/core/notifications_service.dart';

void main() {
  group('homeTabIndexForNotification', () {
    test('a sale-live push opens the Sales tab', () {
      // Search joined the shell at index 1 in US-11, moving Sales to 2.
      expect(homeTabIndexForNotification({'type': 'sale'}), 2);
    });

    test('an offer-live push opens the Discounts tab', () {
      expect(homeTabIndexForNotification({'type': 'offer'}), 3);
    });

    test('an unrecognised or missing type opens nothing in particular', () {
      expect(homeTabIndexForNotification({'type': 'something_else'}), null);
      expect(homeTabIndexForNotification({}), null);
    });
  });
}
