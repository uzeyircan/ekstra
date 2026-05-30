import 'package:ekstra/features/notifications/domain/notification_plan.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';

class NotificationPlanService {
  const NotificationPlanService();

  List<NotificationPlan> buildPlans({
    required DateTime now,
    required UserSettings settings,
    required Iterable<ShiftAssignment> assignments,
  }) {
    if (!settings.notificationsEnabled) return const [];

    final plans = <NotificationPlan>[];
    if (settings.shiftReminderEnabled) {
      plans.addAll(_shiftStartPlans(now: now, assignments: assignments));
    }
    if (settings.overtimeReminderEnabled) {
      plans.addAll(_shiftEndPlans(now: now, assignments: assignments));
    }
    if (settings.salaryReminderEnabled) {
      final salaryPlan = _salaryDayPlan(now, settings.salaryDayOfMonth);
      if (salaryPlan != null) plans.add(salaryPlan);
    }
    if (settings.monthlySummaryReminderEnabled) {
      final summaryPlan = _monthlySummaryPlan(now);
      if (summaryPlan != null) plans.add(summaryPlan);
    }

    plans.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return plans.take(64).toList();
  }

  List<NotificationPlan> _shiftStartPlans({
    required DateTime now,
    required Iterable<ShiftAssignment> assignments,
  }) {
    return assignments
        .map((assignment) {
          final startAt = _dateWithTime(assignment.date, assignment.startTime);
          if (startAt == null) return null;
          final scheduledAt = startAt.subtract(const Duration(minutes: 30));
          if (!scheduledAt.isAfter(now)) return null;
          return NotificationPlan(
            id: _stableId(assignment.id, 10),
            type: EkstraNotificationType.shiftReminder,
            scheduledAt: scheduledAt,
            title: 'Vardiyana 30 dakika kaldı',
            body:
                '${assignment.templateName} vardiyası ${assignment.startTime} saatinde başlıyor.',
          );
        })
        .whereType<NotificationPlan>()
        .toList();
  }

  List<NotificationPlan> _shiftEndPlans({
    required DateTime now,
    required Iterable<ShiftAssignment> assignments,
  }) {
    return assignments
        .map((assignment) {
          final endAt = _dateWithTime(assignment.date, assignment.endTime);
          if (endAt == null) return null;
          final scheduledAt =
              _isOvernight(assignment.startTime, assignment.endTime)
              ? endAt.add(const Duration(days: 1))
              : endAt;
          if (!scheduledAt.isAfter(now)) return null;
          return NotificationPlan(
            id: _stableId(assignment.id, 20),
            type: EkstraNotificationType.overtimeReminder,
            scheduledAt: scheduledAt,
            title: 'Bugünkü mesaini unutma',
            body: 'Vardiyan bittiyse EKSTRA içinde mesaini kaydedebilirsin.',
          );
        })
        .whereType<NotificationPlan>()
        .toList();
  }

  NotificationPlan? _salaryDayPlan(DateTime now, int salaryDayOfMonth) {
    final safeDay = salaryDayOfMonth.clamp(1, 31);
    var scheduledAt = _dateInMonth(now.year, now.month, safeDay, 9);
    if (!scheduledAt.isAfter(now)) {
      scheduledAt = _dateInMonth(now.year, now.month + 1, safeDay, 9);
    }
    return NotificationPlan(
      id: scheduledAt.year * 10000 + scheduledAt.month * 100 + scheduledAt.day,
      type: EkstraNotificationType.salaryDay,
      scheduledAt: scheduledAt,
      title: 'Maaş günü',
      body: 'Bu ayki mesai ve kazanç özetini kontrol edebilirsin.',
    );
  }

  NotificationPlan? _monthlySummaryPlan(DateTime now) {
    var scheduledAt = DateTime(now.year, now.month + 1, 0, 19);
    if (!scheduledAt.isAfter(now)) {
      scheduledAt = DateTime(now.year, now.month + 2, 0, 19);
    }
    return NotificationPlan(
      id: scheduledAt.year * 10000 + scheduledAt.month * 100 + 99,
      type: EkstraNotificationType.monthlySummary,
      scheduledAt: scheduledAt,
      title: 'Ay sonu mesai özeti',
      body: 'Bu ayki fazla mesai saatlerini ve tahmini kazancını incele.',
    );
  }

  DateTime _dateInMonth(int year, int month, int requestedDay, int hour) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay.clamp(1, lastDay), hour);
  }

  DateTime? _dateWithTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isOvernight(String startTime, String endTime) {
    final start = _minutes(startTime);
    final end = _minutes(endTime);
    if (start == null || end == null) return false;
    return end <= start;
  }

  int? _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  int _stableId(String id, int prefix) {
    return prefix * 100000 +
        id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  }
}
