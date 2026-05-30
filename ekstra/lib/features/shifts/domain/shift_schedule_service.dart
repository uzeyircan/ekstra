import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:ekstra/features/shifts/domain/shift_template.dart';

enum ShiftRepeatType { everyDay, weekdays, selectedDays, alternatingWeeks }

class ShiftScheduleService {
  const ShiftScheduleService();

  List<ShiftAssignment> buildMonthlyAssignments({
    required ShiftTemplate template,
    required DateTime month,
    required ShiftRepeatType repeatType,
    required Set<int> selectedWeekdays,
    ShiftTemplate? alternateTemplate,
  }) {
    final start = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();
    final assignments = <ShiftAssignment>[];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final resolvedTemplate = _templateForDate(
        primary: template,
        alternate: alternateTemplate,
        repeatType: repeatType,
        date: date,
        start: start,
      );
      if (resolvedTemplate == null) continue;
      if (!_shouldAssign(date, repeatType, selectedWeekdays)) continue;

      assignments.add(
        ShiftAssignment(
          id: DateKey.fromDate(date),
          date: date,
          templateId: resolvedTemplate.id,
          templateName: resolvedTemplate.name,
          startTime: resolvedTemplate.startTime,
          endTime: resolvedTemplate.endTime,
          color: resolvedTemplate.color,
          createdAt: now,
        ),
      );
    }

    return assignments;
  }

  ShiftAssignment? todayAssignment(
    Iterable<ShiftAssignment> assignments,
    DateTime now,
  ) {
    for (final assignment in assignments) {
      if (DateKey.isSameDay(assignment.date, now)) return assignment;
    }
    return null;
  }

  bool _shouldAssign(
    DateTime date,
    ShiftRepeatType repeatType,
    Set<int> selectedWeekdays,
  ) {
    return switch (repeatType) {
      ShiftRepeatType.everyDay => true,
      ShiftRepeatType.weekdays => date.weekday <= DateTime.friday,
      ShiftRepeatType.selectedDays => selectedWeekdays.contains(date.weekday),
      ShiftRepeatType.alternatingWeeks => true,
    };
  }

  ShiftTemplate? _templateForDate({
    required ShiftTemplate primary,
    required ShiftTemplate? alternate,
    required ShiftRepeatType repeatType,
    required DateTime date,
    required DateTime start,
  }) {
    if (repeatType != ShiftRepeatType.alternatingWeeks) return primary;
    if (alternate == null) return primary;

    final daysFromStart = date.difference(start).inDays;
    final weekIndex = daysFromStart ~/ 7;
    return weekIndex.isEven ? primary : alternate;
  }
}
