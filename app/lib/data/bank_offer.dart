import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';

/// A bank discount, whether it arrived scoped to one brand
/// (`GET /brands/{slug}/offers`, the toolbar chips) or from the cross-brand
/// directory (`GET /offers`).
///
/// The API only ever returns desk-verified offers inside their validity window,
/// so everything here is safe to show with the "Verified" badge.
class BankOffer {
  const BankOffer({
    required this.id,
    required this.bankSlug,
    required this.bankName,
    required this.cardTypes,
    required this.channel,
    this.brandSlug,
    this.brandName,
    this.discountPct,
    this.maxDiscountAmount,
    this.minSpend,
    this.validFrom,
    this.validTo,
    this.proofUrl,
  });

  factory BankOffer.fromJson(Map<String, dynamic> json) => BankOffer(
    id: json['id'] as int,
    bankSlug: json['bank_slug'] as String,
    bankName: json['bank_name'] as String,
    cardTypes: (json['card_types'] as List).cast<String>(),
    channel: json['channel'] as String,
    brandSlug: json['brand_slug'] as String?,
    brandName: json['brand_name'] as String?,
    discountPct: (json['discount_pct'] as num?)?.toDouble(),
    maxDiscountAmount: (json['max_discount_amt'] as num?)?.toDouble(),
    minSpend: (json['min_spend'] as num?)?.toDouble(),
    validFrom: _parseDate(json['valid_from'] as String?),
    validTo: _parseDate(json['valid_to'] as String?),
    proofUrl: json['proof_url'] as String?,
  );

  final int id;

  /// The bank's stable identity — what "my cards" is saved against.
  final String bankSlug;
  final String bankName;

  /// Null when the offer is not tied to a single brand: in the directory that
  /// means it works everywhere, and the chips never read it because the brand
  /// being browsed is already the answer.
  final String? brandSlug;
  final String? brandName;

  /// credit | debit | islamic | wallet | bnpl
  final List<String> cardTypes;

  /// online | instore | both
  final String channel;
  final double? discountPct;
  final double? maxDiscountAmount;
  final double? minSpend;
  final DateTime? validFrom;
  final DateTime? validTo;

  /// The bank's own offer page — the shopper's way of checking us.
  final String? proofUrl;
}

DateTime? _parseDate(String? value) =>
    value == null ? null : DateTime.parse(value);

/// Requested when the brand screen opens, so the chips are ready well before the
/// brand's own page has finished loading.
final brandOffersProvider = FutureProvider.family<List<BankOffer>, String>(
  (ref, slug) async {
    final payload = await ref.watch(apiClientProvider).fetchBrandOffers(slug);
    return payload.map(BankOffer.fromJson).toList();
  },
);
