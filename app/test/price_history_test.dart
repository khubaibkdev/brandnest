import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brandnest/data/price_history_repository.dart';
import 'package:brandnest/features/brand_webview/price_graph_sheet.dart';

PriceHistory _history({
  required String verdict,
  int windowDays = 37,
  List<(String, double)> points = const [('2026-07-25', 4000), ('2026-08-30', 3000)],
}) => PriceHistory.fromJson({
  'points': [
    for (final (on, price) in points) {'on': on, 'price': price},
  ],
  'window_days': windowDays,
  'verdict': verdict,
  'current_price': points.last.$2,
  'typical_price': 4000,
  'lowest_price': 3000,
});

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('PriceHistory parsing', () {
    test('reads the series and the verdict', () {
      final history = _history(verdict: 'genuine');

      expect(history.points, hasLength(2));
      expect(history.points.first.on, DateTime(2026, 7, 25));
      expect(history.points.last.price, 3000);
      expect(history.verdict, PriceVerdict.genuine);
      expect(history.isAsliSale, isTrue);
      expect(history.windowDays, 37);
    });

    test('an unrecognised verdict never claims a sale', () {
      expect(_history(verdict: 'something_new').isAsliSale, isFalse);
    });

    test('a product with no history parses without prices', () {
      final history = PriceHistory.fromJson({
        'points': <Map<String, dynamic>>[],
        'window_days': 0,
        'verdict': 'no_history',
        'current_price': null,
        'typical_price': null,
        'lowest_price': null,
      });

      expect(history.points, isEmpty);
      expect(history.verdict, PriceVerdict.noHistory);
      expect(history.currentPrice, isNull);
    });
  });

  group('the verdict people actually read', () {
    testWidgets('a genuine drop is badged an Asli Sale', (tester) async {
      await tester.pumpWidget(
        _wrap(PriceReport(title: 'A Shirt', history: _history(verdict: 'genuine'))),
      );

      expect(find.text('Asli Sale'), findsOneWidget);
      expect(find.textContaining('PKR 4,000'), findsWidgets);
    });

    testWidgets('a price that never moved is not sold as a discount', (tester) async {
      await tester.pumpWidget(
        _wrap(PriceReport(title: 'A Shirt', history: _history(verdict: 'not_lowest'))),
      );

      expect(find.text('Asli Sale'), findsNothing);
      expect(find.text('This is the usual price'), findsOneWidget);
    });

    testWidgets('a pre-sale markup is called out', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PriceReport(title: 'A Shirt', history: _history(verdict: 'pre_sale_markup')),
        ),
      );

      expect(find.text('Price was raised first'), findsOneWidget);
    });

    testWidgets('the note says how long we really watched, not 90 days', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PriceReport(
            title: 'A Shirt',
            history: _history(verdict: 'genuine', windowDays: 37),
          ),
        ),
      );

      expect(find.text('Based on 37 days of price checks so far.'), findsOneWidget);
      expect(find.textContaining('90'), findsNothing);
    });
  });

  group('the chart', () {
    testWidgets('draws once there are at least two days to draw', (tester) async {
      await tester.pumpWidget(
        _wrap(PriceReport(title: 'A Shirt', history: _history(verdict: 'genuine'))),
      );

      expect(find.byType(PriceChart), findsOneWidget);
    });

    testWidgets('a single day of history shows the verdict without a chart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PriceReport(
            title: 'A Shirt',
            history: _history(
              verdict: 'not_lowest',
              windowDays: 1,
              points: const [('2026-08-30', 3000)],
            ),
          ),
        ),
      );

      expect(find.byType(PriceChart), findsNothing);
      expect(find.text('Based on 1 day of price checks so far.'), findsOneWidget);
    });

    testWidgets('a flat price paints without dividing by zero', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PriceReport(
            title: 'A Shirt',
            history: _history(
              verdict: 'not_lowest',
              points: const [('2026-07-25', 4000), ('2026-08-30', 4000)],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PriceChart), findsOneWidget);
    });
  });
}
