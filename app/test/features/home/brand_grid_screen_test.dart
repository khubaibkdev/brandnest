import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/features/home/brand_grid_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  testWidgets('renders cached brands and their categories while offline', (
    tester,
  ) async {
    await database.replaceBrands([
      BrandsCompanion.insert(
        id: const Value(1),
        slug: 'outfitters',
        name: 'Outfitters',
        categories: ['women', 'men'],
        websiteUrl: 'https://outfitters.com.pk',
        platform: 'shopify',
      ),
      BrandsCompanion.insert(
        id: const Value(4),
        slug: 'limelight',
        name: 'Limelight',
        categories: ['women'],
        websiteUrl: 'https://limelight.pk',
        platform: 'shopify',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiClientProvider.overrideWithValue(
            ApiClient(
              httpClient: MockClient((_) async => throw const SocketFailure()),
            ),
          ),
        ],
        child: const MaterialApp(home: BrandGridScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outfitters'), findsOneWidget);
    expect(find.text('Limelight'), findsOneWidget);
    // Tabs are driven by the cached data: no brand is tagged kids or shoes.
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
    expect(find.text('Men'), findsOneWidget);
    expect(find.text('Kids'), findsNothing);
    expect(find.text('Shoes'), findsNothing);
    expect(find.text('Offline — showing saved brands.'), findsOneWidget);

    // Unmount inside the test body so the SnackBar timer and Drift's
    // stream-close timer both fire before the framework checks for leaks.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}

class SocketFailure implements Exception {
  const SocketFailure();
}
