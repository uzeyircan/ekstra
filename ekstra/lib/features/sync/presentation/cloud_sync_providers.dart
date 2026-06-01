import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/sync/data/cloud_backup_service.dart';
import 'package:ekstra/features/sync/domain/cloud_sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService(hive: ref.watch(hiveServiceProvider));
});

final latestCloudSyncAtProvider = Provider<DateTime?>((ref) {
  final value = ref
      .watch(hiveServiceProvider)
      .integrityBox
      .get(AppConstants.latestCloudSyncAtKey);
  if (value is! String) return null;
  return DateTime.tryParse(value);
});

final cloudSyncControllerProvider =
    AsyncNotifierProvider<CloudSyncController, CloudSyncResult?>(
      CloudSyncController.new,
    );

class CloudSyncController extends AsyncNotifier<CloudSyncResult?> {
  CloudBackupService get _service => ref.read(cloudBackupServiceProvider);

  @override
  Future<CloudSyncResult?> build() async => null;

  Future<CloudSyncResult> upload() async {
    state = const AsyncLoading();
    final result = await _service.upload();
    state = AsyncData(result);
    ref.invalidate(latestCloudSyncAtProvider);
    return result;
  }

  Future<CloudSyncResult> restoreMissing() async {
    state = const AsyncLoading();
    final result = await _service.restoreMissing();
    state = AsyncData(result);
    ref.invalidate(latestCloudSyncAtProvider);
    return result;
  }
}
