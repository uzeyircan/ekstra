import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/ads/domain/rewarded_ad_result.dart';
import 'package:ekstra/features/ads/presentation/ad_providers.dart';
import 'package:ekstra/features/monetization/domain/feature_gate.dart';
import 'package:ekstra/features/monetization/domain/monetized_feature.dart';
import 'package:ekstra/features/monetization/presentation/entitlement_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<bool> requireRewardedAdOrPro({
  required BuildContext context,
  required WidgetRef ref,
  required MonetizedFeature feature,
  required String title,
  required String message,
}) async {
  final gate = ref.read(featureGateProvider);
  final access = gate.accessFor(feature);
  if (access == FeatureAccess.allowed) return true;
  if (access == FeatureAccess.proRequired) {
    if (!context.mounted) return false;
    await _showProRequiredDialog(context, title, message);
    return false;
  }

  final accepted = await _showRewardedIntroDialog(context, title, message);
  if (accepted != true || !context.mounted) return false;
  final result = await ref.read(rewardedAdServiceProvider).show();
  if (result == RewardedAdResult.rewarded) return true;
  if (!context.mounted) return false;
  final errorText = switch (result) {
    RewardedAdResult.unavailable =>
      'Şu an reklam hazır değil. Biraz sonra tekrar deneyebilirsin.',
    RewardedAdResult.dismissed =>
      'Reklam tamamlanmadığı için özellik açılmadı.',
    RewardedAdResult.failed =>
      'Reklam gösterilirken sorun oluştu. Lütfen tekrar dene.',
    RewardedAdResult.rewarded => '',
  };
  if (errorText.isNotEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorText)));
  }
  return false;
}

Future<void> _showProRequiredDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text('$message\n\nBu özellik Ekstra Pro ile kullanılabilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Daha sonra'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/pro');
            },
            child: const Text('Pro’ya geç'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showRewardedIntroDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.22),
                ),
              ),
              child: const Text(
                'Bu özelliği ücretsiz kullanmak için kısa bir reklam izleyebilirsin. Pro’ya geçersen reklamsız kullanırsın.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Daha sonra'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              context.go('/pro');
            },
            child: const Text('Pro’ya geç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reklam izle'),
          ),
        ],
      );
    },
  );
}
