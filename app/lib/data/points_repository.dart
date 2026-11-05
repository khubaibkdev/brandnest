import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';

/// The shopper's points balance and streak (US-10). Always live from the
/// account — unlike brands/sales/offers there is nothing to cache offline,
/// since a balance only means something as of right now.
class PointsStatus {
  const PointsStatus({
    required this.balance,
    required this.pending,
    required this.streakDays,
    required this.checkedInToday,
    required this.rewardedAdsRemainingToday,
  });

  final int balance;

  /// Order points still inside their return window (US-18) — earned, but not
  /// yet spendable.
  final int pending;

  final int streakDays;
  final bool checkedInToday;
  final int rewardedAdsRemainingToday;

  factory PointsStatus.fromJson(Map<String, dynamic> json) => PointsStatus(
    balance: json['balance'] as int,
    pending: json['pending'] as int? ?? 0,
    streakDays: json['streak_days'] as int,
    checkedInToday: json['checked_in_today'] as bool,
    rewardedAdsRemainingToday: json['rewarded_ads_remaining_today'] as int,
  );
}

/// What a check-in or a rewarded-ad report returns: the same status, plus
/// whether this particular call actually paid out — false for "already
/// checked in today" or "hit the daily ad cap," not an error.
class PointsActionResult extends PointsStatus {
  const PointsActionResult({
    required super.balance,
    required super.pending,
    required super.streakDays,
    required super.checkedInToday,
    required super.rewardedAdsRemainingToday,
    required this.awarded,
  });

  final bool awarded;

  factory PointsActionResult.fromJson(Map<String, dynamic> json) =>
      PointsActionResult(
        balance: json['balance'] as int,
        pending: json['pending'] as int? ?? 0,
        streakDays: json['streak_days'] as int,
        checkedInToday: json['checked_in_today'] as bool,
        rewardedAdsRemainingToday: json['rewarded_ads_remaining_today'] as int,
        awarded: json['awarded'] as bool,
      );
}

class PointsRepository {
  PointsRepository(this._apiClient, [this._getIdToken = noIdToken]);

  final ApiClient _apiClient;
  final IdTokenProvider _getIdToken;

  Future<PointsStatus> fetch() async => PointsStatus.fromJson(
    await _apiClient.fetchPoints(await _requireIdToken()),
  );

  Future<PointsActionResult> checkIn() async => PointsActionResult.fromJson(
    await _apiClient.checkIn(await _requireIdToken()),
  );

  /// `clientRef` is one UUID-ish string per ad watched, so a retried request
  /// cannot pay out twice for the same view.
  Future<PointsActionResult> reportRewardedAd(String clientRef) async =>
      PointsActionResult.fromJson(
        await _apiClient.postRewardedAd(await _requireIdToken(), clientRef),
      );

  /// Report a completed order (US-18). Returns null when the server did not
  /// recognise the page as a confirmation — the app deliberately does not
  /// decide that for itself.
  Future<PointsActionResult?> reportOrder(String brandSlug, String url) async {
    final body = await _apiClient.postOrder(
      await _requireIdToken(),
      brandSlug,
      url,
    );
    return body == null ? null : PointsActionResult.fromJson(body);
  }

  Future<String> _requireIdToken() async {
    final idToken = await _getIdToken();
    if (idToken == null) throw StateError('Not signed in yet');
    return idToken;
  }
}

final pointsRepositoryProvider = Provider<PointsRepository>(
  (ref) => PointsRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);

final pointsProvider = FutureProvider<PointsStatus>(
  (ref) => ref.watch(pointsRepositoryProvider).fetch(),
);
