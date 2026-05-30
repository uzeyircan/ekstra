import 'package:ekstra/features/notifications/domain/notification_plan.dart';
import 'package:ekstra/features/notifications/domain/notification_plan_service.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification planner returns nothing when disabled', () {
    const service = NotificationPlanService();

    final plans = service.buildPlans(
      now: DateTime(2026, 5, 28),
      settings: UserSettings.defaults(),
      assignments: const [],
    );

    expect(plans, isEmpty);
  });

  test('notification planner builds shift and salary reminders', () {
    const service = NotificationPlanService();
    final now = DateTime(2026, 5, 28, 7);
    final settings = UserSettings.defaults().copyWith(
      notificationsEnabled: true,
      salaryDayOfMonth: 31,
    );
    final assignments = [
      ShiftAssignment(
        id: '2026-05-28',
        date: DateTime(2026, 5, 28),
        templateId: 'morning',
        templateName: 'Sabah',
        startTime: '08:00',
        endTime: '16:00',
        color: 0xFF2ED573,
        createdAt: now,
      ),
    ];

    final plans = service.buildPlans(
      now: now,
      settings: settings,
      assignments: assignments,
    );

    expect(
      plans.map((plan) => plan.type),
      containsAll([
        EkstraNotificationType.shiftReminder,
        EkstraNotificationType.overtimeReminder,
        EkstraNotificationType.salaryDay,
        EkstraNotificationType.monthlySummary,
      ]),
    );
    expect(
      plans
          .firstWhere(
            (plan) => plan.type == EkstraNotificationType.shiftReminder,
          )
          .scheduledAt,
      DateTime(2026, 5, 28, 7, 30),
    );
  });

  test('notification planner schedules overnight shift end next day', () {
    const service = NotificationPlanService();
    final now = DateTime(2026, 5, 28, 15);
    final settings = UserSettings.defaults().copyWith(
      notificationsEnabled: true,
      shiftReminderEnabled: false,
      salaryReminderEnabled: false,
      monthlySummaryReminderEnabled: false,
    );
    final assignments = [
      ShiftAssignment(
        id: '2026-05-28',
        date: DateTime(2026, 5, 28),
        templateId: 'night',
        templateName: 'Gece',
        startTime: '16:00',
        endTime: '00:00',
        color: 0xFF70A1FF,
        createdAt: now,
      ),
    ];

    final plans = service.buildPlans(
      now: now,
      settings: settings,
      assignments: assignments,
    );

    expect(plans.single.scheduledAt, DateTime(2026, 5, 29));
  });
}
