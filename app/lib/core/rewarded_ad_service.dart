import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's public test rewarded-ad unit (US-10): real ad creative, no AdMob
/// account needed. Swap for the founder's own ad unit ID before the closed
/// beta — see PROGRESS.md.
const _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

class RewardedAdService {
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Loads and immediately shows a rewarded ad. [onEarned] fires once the
  /// shopper watches it through; [onFailed] otherwise — no fill, offline, or
  /// dismissed early — and the shopper simply doesn't get points for it.
  void watch({
    required void Function() onEarned,
    required void Function(String reason) onFailed,
  }) {
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onFailed(error.message);
            },
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
          );
          ad.show(onUserEarnedReward: (_, _) => onEarned());
        },
        onAdFailedToLoad: (error) => onFailed(error.message),
      ),
    );
  }
}

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(),
);
