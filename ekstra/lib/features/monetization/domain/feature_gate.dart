import 'package:ekstra/features/monetization/domain/monetized_feature.dart';
import 'package:ekstra/features/monetization/domain/user_entitlement.dart';

enum FeatureAccess { allowed, rewardedAdAvailable, proRequired }

class FeatureGate {
  const FeatureGate(this.entitlement);

  final UserEntitlement entitlement;

  bool get isPro => entitlement.isPro;

  FeatureAccess accessFor(MonetizedFeature feature) {
    if (isPro) return FeatureAccess.allowed;
    return switch (feature) {
      MonetizedFeature.pdfExport => FeatureAccess.rewardedAdAvailable,
      MonetizedFeature.excelExport => FeatureAccess.rewardedAdAvailable,
      MonetizedFeature.advancedMonthlyAnalysis =>
        FeatureAccess.rewardedAdAvailable,
      MonetizedFeature.advancedSalarySummary =>
        FeatureAccess.rewardedAdAvailable,
      MonetizedFeature.advancedNotifications => FeatureAccess.proRequired,
      MonetizedFeature.advancedWidget => FeatureAccess.proRequired,
      MonetizedFeature.fullHistoryReports => FeatureAccess.proRequired,
    };
  }

  bool canUsePdfExport() {
    return accessFor(MonetizedFeature.pdfExport) == FeatureAccess.allowed;
  }

  bool canUseAdvancedAnalysis() {
    return accessFor(MonetizedFeature.advancedMonthlyAnalysis) ==
        FeatureAccess.allowed;
  }

  bool requiresRewardedAdOrPro(MonetizedFeature feature) {
    return accessFor(feature) == FeatureAccess.rewardedAdAvailable;
  }
}
