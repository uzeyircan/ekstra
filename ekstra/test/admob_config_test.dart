import 'package:ekstra/core/config/admob_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admob config exposes a rewarded test ad unit by default', () {
    expect(AdMobConfig.rewardedAdUnitId, startsWith('ca-app-pub-'));
  });
}
