import 'package:ekstra/core/config/admob_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  const AdService();

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    if (!AdMobConfig.hasRewardedAdUnitId) return;
    await MobileAds.instance.initialize();
  }
}
