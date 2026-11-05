import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brandnest/core/api_client.dart';
import 'package:brandnest/core/auth_service.dart';

/// Whether the shopper is already watching the product currently on screen
/// (US-13), and enough identity (`productId`) to toggle it. `productId` null
/// means the toolbar detected a product page our crawler hasn't seen yet —
/// the Watch toggle simply doesn't show for it.
class WatchStatus {
  const WatchStatus({
    required this.productId,
    required this.title,
    required this.watching,
  });

  final int? productId;
  final String? title;
  final bool watching;

  factory WatchStatus.fromJson(Map<String, dynamic> json) => WatchStatus(
    productId: json['product_id'] as int?,
    title: json['title'] as String?,
    watching: json['watching'] as bool,
  );
}

class WatchRepository {
  WatchRepository(this._apiClient, [this._getIdToken = noIdToken]);

  final ApiClient _apiClient;
  final IdTokenProvider _getIdToken;

  Future<WatchStatus> fetchStatus(String brandSlug, String productUrl) async =>
      WatchStatus.fromJson(
        await _apiClient.fetchWatchStatus(
          await _requireIdToken(),
          brandSlug,
          productUrl,
        ),
      );

  Future<void> startWatching(int productId) async =>
      _apiClient.createWatch(await _requireIdToken(), productId);

  Future<void> stopWatching(int productId) async =>
      _apiClient.deleteWatch(await _requireIdToken(), productId);

  Future<String> _requireIdToken() async {
    final idToken = await _getIdToken();
    if (idToken == null) throw StateError('Not signed in yet');
    return idToken;
  }
}

final watchRepositoryProvider = Provider<WatchRepository>(
  (ref) => WatchRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider).idToken,
  ),
);
