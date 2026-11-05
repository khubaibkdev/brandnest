import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';

/// Push subscriptions for US-6: a topic per active brand for sale-start
/// alerts, a topic per bank the shopper carries a card from for offer-live
/// alerts. There is no per-brand follow feature, so "subscribed" starts as
/// "every brand/bank we know about" and the per-category toggle is the only
/// opt-out.
///
/// Subscribing twice is harmless on Firebase's side, so this only needs to
/// track what it has already asked for *in this process* well enough to
/// unsubscribe what fell out of the desired set — it does not persist across
/// restarts, and re-subscribing everything after a cold start costs nothing.
///
/// Also registers this device's own FCM token (US-13's direct-to-device watch
/// alerts need somewhere to look one up) and keeps it current — Firebase can
/// reissue a token during a long-lived install, and a stale one silently
/// means no more watch alerts until someone happens to reinstall.
class NotificationsService {
  NotificationsService(
    this._messaging,
    this._apiClient, [
    this._getIdToken = noIdToken,
  ]);

  final FirebaseMessaging _messaging;
  final ApiClient _apiClient;
  final IdTokenProvider _getIdToken;
  Set<String> _saleTopics = {};
  Set<String> _offerTopics = {};

  Future<void> requestPermission() => _messaging.requestPermission();

  Future<void> registerDeviceToken() async {
    final token = await _messaging.getToken();
    final idToken = await _getIdToken();
    if (token == null || idToken == null) return;
    try {
      await _apiClient.registerDeviceToken(idToken, token);
    } catch (_) {
      // Best-effort — a missed registration just means no watch alerts until
      // the next successful one, not a reason to block the app opening.
    }
  }

  /// Call once, after the app is up — not from [registerDeviceToken] itself,
  /// so a token refresh doesn't attach a second listener each time it fires.
  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((_) => registerDeviceToken());
  }

  Future<void> syncSaleTopics(Iterable<String> brandSlugs, bool enabled) async {
    final desired = enabled
        ? brandSlugs.map((slug) => 'sale-$slug').toSet()
        : <String>{};
    _saleTopics = await _sync(_saleTopics, desired);
  }

  Future<void> syncOfferTopics(Iterable<String> bankSlugs, bool enabled) async {
    final desired = enabled
        ? bankSlugs.map((slug) => 'offer-$slug').toSet()
        : <String>{};
    _offerTopics = await _sync(_offerTopics, desired);
  }

  Future<Set<String>> _sync(Set<String> current, Set<String> desired) async {
    for (final topic in desired.difference(current)) {
      await _messaging.subscribeToTopic(topic);
    }
    for (final topic in current.difference(desired)) {
      await _messaging.unsubscribeFromTopic(topic);
    }
    return desired;
  }
}

/// Which tab a push should open, from the `data` payload `deals.py` sends —
/// `{"type": "sale", ...}` or `{"type": "offer", ...}`. Pure so it is testable
/// without a real [RemoteMessage].
/// Indices into [HomeShell]'s destinations, which Search joined at 1 in
/// US-11 — Sales and Discounts each moved one to the right, and a US-6 push
/// that still said 1 and 2 would open the wrong tab.
int? homeTabIndexForNotification(Map<String, dynamic> data) => switch (data['type']) {
  'sale' => 2,
  'offer' => 3,
  // A US-14 decision: My reports hangs off the Discounts tab.
  'report' => 3,
  _ => null,
};

final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => NotificationsService(
    FirebaseMessaging.instance,
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);
