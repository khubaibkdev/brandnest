import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';

/// What the backend concluded about a product's discount (US-12,
/// CRAWLER_PLAYBOOK §3). The rules live server-side — the app only renders the
/// answer, so the badge can never disagree with itself across app versions.
enum PriceVerdict {
  /// Below its own typical price, with no markup beforehand — a real sale.
  genuine,

  /// Today's price is the normal price. Whatever the page's struck-through
  /// number claims, nothing is actually off right now.
  notLowest,

  /// Raised recently, then "discounted" back down.
  preSaleMarkup,

  /// Never crawled with a price — no opinion to offer.
  noHistory;

  static PriceVerdict parse(String value) => switch (value) {
    'genuine' => PriceVerdict.genuine,
    'pre_sale_markup' => PriceVerdict.preSaleMarkup,
    'no_history' => PriceVerdict.noHistory,
    _ => PriceVerdict.notLowest,
  };
}

class PricePoint {
  const PricePoint({required this.on, required this.price});

  final DateTime on;
  final double price;
}

class PriceHistory {
  const PriceHistory({
    required this.points,
    required this.windowDays,
    required this.verdict,
    required this.currentPrice,
    required this.typicalPrice,
    required this.lowestPrice,
  });

  final List<PricePoint> points;

  /// Days the series really covers. The crawl is younger than the 90 days the
  /// rule is written against, so the UI says "in N days" rather than implying
  /// a window we don't have.
  final int windowDays;

  final PriceVerdict verdict;
  final double? currentPrice;
  final double? typicalPrice;
  final double? lowestPrice;

  bool get isAsliSale => verdict == PriceVerdict.genuine;

  factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
    points: [
      for (final point in json['points'] as List)
        PricePoint(
          on: DateTime.parse(point['on'] as String),
          price: (point['price'] as num).toDouble(),
        ),
    ],
    windowDays: json['window_days'] as int,
    verdict: PriceVerdict.parse(json['verdict'] as String),
    currentPrice: (json['current_price'] as num?)?.toDouble(),
    typicalPrice: (json['typical_price'] as num?)?.toDouble(),
    lowestPrice: (json['lowest_price'] as num?)?.toDouble(),
  );
}

class PriceHistoryRepository {
  PriceHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PriceHistory> fetch(int productId) async =>
      PriceHistory.fromJson(await _apiClient.fetchPriceHistory(productId));
}

final priceHistoryRepositoryProvider = Provider<PriceHistoryRepository>(
  (ref) => PriceHistoryRepository(ref.watch(apiClientProvider)),
);

/// Not cached in Drift: the graph is only ever opened from a product page the
/// shopper is already browsing online, so an offline copy would have no reader.
final priceHistoryProvider = FutureProvider.family<PriceHistory, int>(
  (ref, productId) => ref.watch(priceHistoryRepositoryProvider).fetch(productId),
);
