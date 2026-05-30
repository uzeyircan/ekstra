import 'package:ekstra/features/notifications/data/local_notification_service.dart';
import 'package:ekstra/features/notifications/domain/notification_plan_service.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/shifts/presentation/shift_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

final notificationPlanServiceProvider = Provider<NotificationPlanService>((
  ref,
) {
  return const NotificationPlanService();
});

final notificationSyncControllerProvider = Provider<NotificationSyncController>(
  (ref) => NotificationSyncController(ref),
);

class NotificationSyncController {
  const NotificationSyncController(this._ref);

  final Ref _ref;

  Future<void> sync() async {
    final settings = _ref.read(settingsControllerProvider).value;
    if (settings == null) return;
    final notificationService = _ref.read(localNotificationServiceProvider);
    await notificationService.initialize();
    if (!settings.notificationsEnabled) {
      await notificationService.cancelAll();
      return;
    }
    await notificationService.requestPermissions();
    final assignments = _ref.read(shiftAssignmentsProvider).value ?? [];
    final plans = _ref
        .read(notificationPlanServiceProvider)
        .buildPlans(
          now: DateTime.now(),
          settings: settings,
          assignments: assignments,
        );
    await notificationService.schedulePlans(plans);
  }
}
