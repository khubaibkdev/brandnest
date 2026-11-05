import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';

/// Reads always come from the Drift cache so the grid works offline;
/// [refresh] is what talks to the API.
class BrandRepository {
  BrandRepository(this._apiClient, this._database);

  final ApiClient _apiClient;
  final AppDatabase _database;

  Stream<List<Brand>> watchBrands() => _database.watchBrands();

  Future<void> refresh() async {
    final payload = await _apiClient.fetchBrands();
    await _database.replaceBrands(payload.map(_toRow).toList());
  }

  BrandsCompanion _toRow(Map<String, dynamic> json) => BrandsCompanion.insert(
    id: Value(json['id'] as int),
    slug: json['slug'] as String,
    name: json['name'] as String,
    logoUrl: Value(json['logo_url'] as String?),
    categories: (json['categories'] as List).cast<String>(),
    websiteUrl: json['website_url'] as String,
    platform: json['platform'] as String,
  );
}

final brandRepositoryProvider = Provider<BrandRepository>(
  (ref) => BrandRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  ),
);

final brandsProvider = StreamProvider<List<Brand>>(
  (ref) => ref.watch(brandRepositoryProvider).watchBrands(),
);
