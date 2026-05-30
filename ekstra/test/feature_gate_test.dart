import 'package:ekstra/features/monetization/domain/feature_gate.dart';
import 'package:ekstra/features/monetization/domain/monetized_feature.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free user can unlock exports with rewarded ad', () {
    final gate = FeatureGate(UserEntitlement.free());

    expect(
      gate.accessFor(MonetizedFeature.pdfExport),
      FeatureAccess.rewardedAdAvailable,
    );
    expect(gate.requiresRewardedAdOrPro(MonetizedFeature.pdfExport), isTrue);
    expect(gate.canUsePdfExport(), isFalse);
  });

  test('free user needs pro for advanced persistent features', () {
    final gate = FeatureGate(UserEntitlement.free());

    expect(
      gate.accessFor(MonetizedFeature.advancedWidget),
      FeatureAccess.proRequired,
    );
  });

  test('pro user can use all monetized features', () {
    final gate = FeatureGate(
      UserEntitlement(
        isPro: true,
        source: 'debug_mock',
        updatedAt: DateTime(2026, 5, 30),
      ),
    );

    for (final feature in MonetizedFeature.values) {
      expect(gate.accessFor(feature), FeatureAccess.allowed);
    }
  });
}
