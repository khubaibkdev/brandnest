import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/sale_repository.dart';

import '../fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  SaleRepository repositoryFor(List<Map<String, dynamic>> payload) => SaleRepository(
    ApiClient(
      httpClient: MockClient((_) async => http.Response(jsonEncode(payload), 200)),
    ),
    database,
  );

  test('refresh caches the calendar for offline reading', () async {
    final repository = repositoryFor(salesJson);

    await repository.refresh();

    final cached = await repository.watchSaleEvents().first;
    expect(cached.map((sale) => sale.title), ['Summer Sale', 'Azadi Sale']);
    expect(cached.first.brandName, 'Outfitters');
    expect(cached.first.startsAt, isNull);
    expect(cached.last.startsAt, DateTime.utc(2026, 8, 10, 19).toLocal());
  });

  test('an undated sale sorts ahead of a dated one — it is the one running', () async {
    final repository = repositoryFor(salesJson.reversed.toList());

    await repository.refresh();

    final cached = await repository.watchSaleEvents().first;
    expect(cached.first.title, 'Summer Sale');
  });

  test('refresh drops events the desk has taken down', () async {
    await repositoryFor(salesJson).refresh();
    await repositoryFor([salesJson.first]).refresh();

    final cached = await database.watchSaleEvents().first;
    expect(cached.map((sale) => sale.title), ['Summer Sale']);
  });
}
