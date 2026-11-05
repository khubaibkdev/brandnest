import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/offer_directory_repository.dart';
import 'package:brandnest/features/offers/directory_screen.dart';

import '../../fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> pumpDirectory(WidgetTester tester, {bool online = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient(
                (_) async => online
                    ? http.Response(jsonEncode(directoryOffersJson), 200)
                    : http.Response('down', 500),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: DirectoryScreen()),
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

  Future<void> holdCard(String bankSlug, String cardType) =>
      database.setCardHeld(bankSlug, cardType, true);

  testWidgets('groups every verified discount under its bank', (tester) async {
    await pumpDirectory(tester);

    expect(find.text('Bank Alfalah'), findsOneWidget);
    expect(find.text('Meezan Bank'), findsOneWidget);
    expect(find.text('Standard Chartered'), findsOneWidget);
    expect(find.text('Limelight'), findsOneWidget);
    expect(find.text('20% off'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('says an offer works everywhere when it names no brand', (
    tester,
  ) async {
    await pumpDirectory(tester);

    expect(find.text('All brands'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('asks for the shopper cards before it filters by them', (
    tester,
  ) async {
    await pumpDirectory(tester);

    expect(find.text('Choose my cards'), findsOneWidget);
    expect(find.text('My cards only'), findsNothing);
    // Nothing is hidden while we have not been told anything.
    expect(find.text('Standard Chartered'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('filters down to the cards the shopper holds', (tester) async {
    await holdCard('meezan', 'islamic');

    await pumpDirectory(tester);

    expect(find.text('Meezan Bank'), findsOneWidget);
    expect(find.text('Bank Alfalah'), findsNothing);
    expect(find.text('Standard Chartered'), findsNothing);

    await unmount(tester);
  });

  testWidgets('turning the filter off shows every bank again', (tester) async {
    await holdCard('meezan', 'islamic');
    await pumpDirectory(tester);

    await tester.tap(find.text('My cards only'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Alfalah'), findsOneWidget);
    expect(find.text('Standard Chartered'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('explains itself when no offer suits the saved cards', (
    tester,
  ) async {
    await holdCard('hbl', 'credit');

    await pumpDirectory(tester);

    expect(find.textContaining('No verified discounts for your cards'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('reads the saved directory when the API is unreachable', (
    tester,
  ) async {
    await OfferDirectoryRepository(
      ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(directoryOffersJson), 200),
        ),
      ),
      database,
    ).refresh();

    await pumpDirectory(tester, online: false);

    expect(find.text('Standard Chartered'), findsOneWidget);
    expect(find.text('Offline — showing the saved offers.'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('the picker lists the banks we actually carry offers from', (
    tester,
  ) async {
    await pumpDirectory(tester);

    await tester.tap(find.byIcon(Icons.credit_card));
    await tester.pumpAndSettle();

    expect(find.text('My cards'), findsOneWidget);
    expect(find.text('Islamic'), findsOneWidget);
    expect(find.text('Debit'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('ticking a card in the picker saves it straight away', (
    tester,
  ) async {
    await pumpDirectory(tester);
    await tester.tap(find.byIcon(Icons.credit_card));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Islamic'));
    await tester.pumpAndSettle();

    // The box is drawn from what came back out of the database, so a ticked one
    // is the round trip: nothing here is staged waiting for a Save button.
    final saved = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Islamic'),
    );
    expect(saved.value, isTrue);

    await unmount(tester);
  });

  testWidgets('says so plainly when no offer has been verified yet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient((_) async => http.Response('[]', 200)),
            ),
          ),
        ],
        child: const MaterialApp(home: DirectoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No bank discounts yet'), findsOneWidget);

    await unmount(tester);
  });
}
