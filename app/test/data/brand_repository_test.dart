import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/brand_repository.dart';

import '../fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('refresh writes the API payload into the cache', () async {
    final repository = BrandRepository(
      ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(brandsJson), 200),
        ),
      ),
      database,
    );

    await repository.refresh();

    final cached = await repository.watchBrands().first;
    expect(cached.map((brand) => brand.name), ['Limelight', 'Outfitters']);
    expect(cached.first.categories, ['women']);
  });

  test('refresh replaces brands that are no longer active', () async {
    var payload = brandsJson;
    final repository = BrandRepository(
      ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(payload), 200),
        ),
      ),
      database,
    );

    await repository.refresh();
    payload = [brandsJson.first];
    await repository.refresh();

    final cached = await repository.watchBrands().first;
    expect(cached.map((brand) => brand.name), ['Limelight']);
  });
}
