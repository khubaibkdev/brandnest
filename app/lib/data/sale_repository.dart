import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/data/app_database.dart';

/// Same shape as [BrandRepository]: the calendar reads from Drift so it works
/// offline, and [refresh] is the only thing that needs the network.
class SaleRepository {
  SaleRepository(this._apiClient, this._database);

  final ApiClient _apiClient;
  final AppDatabase _database;

  Stream<List<SaleEvent>> watchSaleEvents() => _database.watchSaleEvents();

  Future<void> refresh() async {
    final payload = await _apiClient.fetchSales();
    await _database.replaceSaleEvents(payload.map(_toRow).toList());
  }

  SaleEventsCompanion _toRow(Map<String, dynamic> json) =>
      SaleEventsCompanion.insert(
        id: Value(json['id'] as int),
        brandSlug: json['brand_slug'] as String,
        brandName: json['brand_name'] as String,
        title: json['title'] as String,
        discountText: Value(json['discount_text'] as String?),
        startsAt: Value(_parseMoment(json['starts_at'] as String?)),
        endsAt: Value(_parseMoment(json['ends_at'] as String?)),
        status: json['status'] as String,
        proofUrl: Value(json['proof_url'] as String?),
      );
}

/// The API speaks UTC; the calendar is read on a phone set to Pakistan time,
/// and a sale belongs to the day the shopper would call it.
DateTime? _parseMoment(String? value) =>
    value == null ? null : DateTime.parse(value).toLocal();

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  ),
);

final saleEventsProvider = StreamProvider<List<SaleEvent>>(
  (ref) => ref.watch(saleRepositoryProvider).watchSaleEvents(),
);
