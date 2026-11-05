import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/calendar/calendar_screen.dart';
import 'package:brandnest/features/calendar/month_view.dart';

import '../../fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  /// Dates relative to now, so the sections a sale falls into never depend on
  /// when the suite happens to run.
  Future<void> cacheTwoSales() => database.replaceSaleEvents([
    SaleEventsCompanion.insert(
      id: const Value(3),
      brandSlug: 'outfitters',
      brandName: 'Outfitters',
      title: 'Summer Sale',
      discountText: const Value('Up to 50% off'),
      status: 'live',
    ),
    SaleEventsCompanion.insert(
      id: const Value(5),
      brandSlug: 'limelight',
      brandName: 'Limelight',
      title: 'Azadi Sale',
      status: 'verified',
      startsAt: Value(DateTime.now().add(const Duration(days: 5))),
      endsAt: Value(DateTime.now().add(const Duration(days: 12))),
    ),
  ]);

  Future<void> pumpCalendar(WidgetTester tester, {required bool online}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient(
                (_) async => online
                    ? http.Response(jsonEncode(salesJson), 200)
                    : http.Response('down', 500),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmount inside the test body so the SnackBar timer and Drift's
  /// stream-close timer fire before the framework checks for leaks.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('sorts sales into where they sit in time', (tester) async {
    await cacheTwoSales();

    await pumpCalendar(tester, online: false);

    expect(find.text('On now'), findsOneWidget);
    expect(find.text('Summer Sale'), findsOneWidget);
    expect(find.text('Live now'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Azadi Sale'), findsOneWidget);
    expect(find.text('Starts in 5 days'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('badges the events a person verified', (tester) async {
    await cacheTwoSales();

    await pumpCalendar(tester, online: false);

    expect(find.text('Verified'), findsNWidgets(2));

    await unmount(tester);
  });

  testWidgets('reads the saved calendar when the API is unreachable', (
    tester,
  ) async {
    await cacheTwoSales();

    await pumpCalendar(tester, online: false);

    expect(find.text('Outfitters'), findsOneWidget);
    expect(find.text('Offline — showing the saved calendar.'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('the month view marks the days a sale runs on', (tester) async {
    await cacheTwoSales();
    await pumpCalendar(tester, online: false);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // The undated sale belongs to no square, so the month view calls it out
    // below the grid. Scoped to the month tab: the list tab stays alive behind it.
    final undatedSection = find.text('Running now, no end date announced');
    await tester.dragUntilVisible(
      undatedSection,
      find.descendant(of: find.byType(MonthView), matching: find.byType(ListView)),
      const Offset(0, -200),
    );

    expect(undatedSection, findsOneWidget);
    expect(
      find.descendant(of: find.byType(MonthView), matching: find.text('Summer Sale')),
      findsOneWidget,
    );

    await unmount(tester);
  });

  testWidgets('says so plainly when nothing is verified yet', (tester) async {
    await pumpCalendar(tester, online: false);

    expect(
      find.textContaining('No verified sales yet'),
      findsOneWidget,
    );

    await unmount(tester);
  });
}
