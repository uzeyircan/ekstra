import 'dart:async';

import 'package:ekstra/core/config/admob_config.dart';
import 'package:ekstra/features/ads/domain/rewarded_ad_result.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService();

  RewardedAd? _ad;
  bool _isLoading = false;

  Future<void> preload() async {
    if (_ad != null || _isLoading) return;
    _isLoading = true;
    final completer = Completer<void>();
    await RewardedAd.load(
      adUnitId: AdMobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          completer.complete();
        },
        onAdFailedToLoad: (_) {
          _isLoading = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  Future<RewardedAdResult> show() async {
    await preload();
    final ad = _ad;
    if (ad == null) return RewardedAdResult.unavailable;

    final completer = Completer<RewardedAdResult>();
    var earnedReward = false;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earnedReward
                ? RewardedAdResult.rewarded
                : RewardedAdResult.dismissed,
          );
        }
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.failed);
        }
        unawaited(preload());
      },
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        earnedReward = true;
      },
    );
    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
