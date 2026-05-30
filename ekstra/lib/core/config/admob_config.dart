import 'package:flutter/foundation.dart';

class AdMobConfig {
  const AdMobConfig._();

  static const androidRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const iosRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  static String get rewardedAdUnitId {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? iosRewardedAdUnitId
        : androidRewardedAdUnitId;
  }
}
