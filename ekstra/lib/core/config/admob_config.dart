import 'package:flutter/foundation.dart';

class AdMobConfig {
  const AdMobConfig._();

  static const _testAndroidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const _testIosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const _androidRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: '',
  );

  static const _iosRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: '',
  );

  static String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosRewardedAdUnitId.isNotEmpty
          ? _iosRewardedAdUnitId
          : (kDebugMode ? _testIosRewardedAdUnitId : '');
    }
    return _androidRewardedAdUnitId.isNotEmpty
        ? _androidRewardedAdUnitId
        : (kDebugMode ? _testAndroidRewardedAdUnitId : '');
  }

  static bool get hasRewardedAdUnitId => rewardedAdUnitId.isNotEmpty;
}
