import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';
import 'package:brandnest/data/app_database.dart';
import 'package:brandnest/data/bank_offer.dart';

/// Still usable today. The API already filtered on this, so it matters for one
/// case: a cached offer that ran out while the phone had no signal. An expired
/// discount on screen is the kind of thing shoppers stop trusting us over.
///
/// The last day counts — an offer "valid till 24 Sep" is usable on the 24th.
bool isOfferCurrent(BankOffer offer, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final from = offer.validFrom;
  final to = offer.validTo;
  return (from == null || !from.isAfter(today)) &&
      (to == null || !to.isBefore(today));
}

/// Same shape as [BrandRepository] and [SaleRepository]: the directory reads
/// from Drift so it works offline, and [refresh] is the only thing that needs
/// the network.
///
/// Unlike those two, rows are mapped back to [BankOffer] rather than served as
/// Drift rows, so the directory and the US-3 toolbar chips share one model and
/// one set of formatters.
class OfferDirectoryRepository {
  OfferDirectoryRepository(
    this._apiClient,
    this._database, [
    this._getIdToken = noIdToken,
  ]);

  final ApiClient _apiClient;
  final AppDatabase _database;
  final IdTokenProvider _getIdToken;

  /// Re-filtered on every emission, which a [refresh] is enough to trigger.
  Stream<List<BankOffer>> watchOffers() =>
      _database.watchDirectoryOffers().map((rows) {
        final now = DateTime.now();
        return rows
            .map(_toOffer)
            .where((offer) => isOfferCurrent(offer, now))
            .toList();
      });

  Stream<List<MyCard>> watchMyCards() => _database.watchMyCards();

  Future<void> setCardHeld(String bankSlug, String cardType, bool held) async {
    await _database.setCardHeld(bankSlug, cardType, held);
    await _pushMyCardsBestEffort();
  }

  /// Reconciles the device's cards with the signed-in account (US-9): a
  /// pending local edit wins and gets pushed, otherwise the account's own
  /// saved set — if it has one — replaces whatever is on the device.
  ///
  /// Called once after sign-in at launch, and again after linking or
  /// switching to a Google account, since a different UID's saved set may
  /// now apply. Silently does nothing offline or signed out — the device
  /// keeps working from whatever it already has.
  Future<void> reconcileMyCards() async {
    final idToken = await _getIdToken();
    if (idToken == null) return;
    try {
      if (await _database.isMyCardsDirty()) {
        await _pushMyCardsBestEffort();
        return;
      }
      final payload = await _apiClient.fetchMyBanks(idToken);
      await _database.replaceMyCards([
        for (final card in payload)
          MyCardsCompanion.insert(
            bankSlug: card['bank_slug'] as String,
            cardType: card['card_type'] as String,
          ),
      ]);
    } catch (_) {
      // Offline or a transient failure — the device keeps its own cards.
    }
  }

  Future<void> _pushMyCardsBestEffort() async {
    final idToken = await _getIdToken();
    if (idToken == null) return;
    try {
      final local = await _database.readMyCards();
      await _apiClient.putMyBanks(idToken, [
        for (final card in local)
          {'bank_slug': card.bankSlug, 'card_type': card.cardType},
      ]);
      await _database.clearMyCardsDirty();
    } catch (_) {
      // Offline — the dirty flag stays set, so the next reconcile retries.
    }
  }

  Future<void> refresh() async {
    final payload = await _apiClient.fetchOffers();
    await _database.replaceDirectoryOffers(payload.map(_toRow).toList());
  }

  DirectoryOffersCompanion _toRow(Map<String, dynamic> json) =>
      DirectoryOffersCompanion.insert(
        id: Value(json['id'] as int),
        bankSlug: json['bank_slug'] as String,
        bankName: json['bank_name'] as String,
        brandSlug: Value(json['brand_slug'] as String?),
        brandName: Value(json['brand_name'] as String?),
        cardTypes: (json['card_types'] as List).cast<String>(),
        discountPct: Value((json['discount_pct'] as num?)?.toDouble()),
        maxDiscountAmount: Value((json['max_discount_amt'] as num?)?.toDouble()),
        minSpend: Value((json['min_spend'] as num?)?.toDouble()),
        channel: json['channel'] as String,
        validFrom: Value(_parseDate(json['valid_from'] as String?)),
        validTo: Value(_parseDate(json['valid_to'] as String?)),
        proofUrl: Value(json['proof_url'] as String?),
      );

  BankOffer _toOffer(DirectoryOffer row) => BankOffer(
    id: row.id,
    bankSlug: row.bankSlug,
    bankName: row.bankName,
    brandSlug: row.brandSlug,
    brandName: row.brandName,
    cardTypes: row.cardTypes,
    channel: row.channel,
    discountPct: row.discountPct,
    maxDiscountAmount: row.maxDiscountAmount,
    minSpend: row.minSpend,
    validFrom: row.validFrom,
    validTo: row.validTo,
    proofUrl: row.proofUrl,
  );
}

/// Validity is a plain date, so it is the shopper's own day that decides —
/// no timezone conversion, unlike the sale calendar's timestamps.
DateTime? _parseDate(String? value) =>
    value == null ? null : DateTime.parse(value);

final offerDirectoryRepositoryProvider = Provider<OfferDirectoryRepository>(
  (ref) => OfferDirectoryRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);

final directoryOffersProvider = StreamProvider<List<BankOffer>>(
  (ref) => ref.watch(offerDirectoryRepositoryProvider).watchOffers(),
);

final myCardsProvider = StreamProvider<List<MyCard>>(
  (ref) => ref.watch(offerDirectoryRepositoryProvider).watchMyCards(),
);
