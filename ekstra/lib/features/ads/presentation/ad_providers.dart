import 'package:ekstra/features/ads/data/ad_service.dart';
import 'package:ekstra/features/ads/data/rewarded_ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return const AdService();
});

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final service = RewardedAdService();
  ref.onDispose(service.dispose);
  return service;
});
