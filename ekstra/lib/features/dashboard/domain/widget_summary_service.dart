import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/dashboard/domain/widget_summary.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/payroll/domain/salary_estimate_service.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';

class WidgetSummaryService {
  const WidgetSummaryService();

  WidgetSummary build({
    required DateTime now,
    required UserSettings settings,
    required Iterable<OvertimeEntry> entries,
    required Iterable<ShiftAssignment> assignments,
  }) {
    final monthEntries = entries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList();
    const salaryService = SalaryEstimateService();
    final salary = salaryService.calculate(
      overtimeEntries: monthEntries,
      monthlyNetSalary: settings.monthlyNetSalary,
      hourlyRate: settings.hourlyRate,
      defaultMultiplier: settings.defaultMultiplier,
      monthlyWorkHours: settings.monthlyWorkHours,
    );
    final todayShift = assignments
        .where((assignment) => DateKey.isSameDay(assignment.date, now))
        .firstOrNull;

    return WidgetSummary(
      todayShiftLabel: todayShift?.templateName ?? '',
      todayShiftTimeRange: todayShift == null
          ? ''
          : '${todayShift.startTime}-${todayShift.endTime}',
      monthlyOvertimeHours: salary.totalOvertimeHours,
      monthlyEstimatedEarnings: salary.estimatedTotalEarnings,
      daysUntilSalaryDay: _daysUntilSalaryDay(
        now: now,
        salaryDayOfMonth: settings.salaryDayOfMonth,
      ),
      generatedAt: now,
    );
  }

  int _daysUntilSalaryDay({
    required DateTime now,
    required int salaryDayOfMonth,
  }) {
    final safeDay = salaryDayOfMonth.clamp(1, 31);
    var target = _dateInMonth(now.year, now.month, safeDay);
    final today = DateTime(now.year, now.month, now.day);
    if (target.isBefore(today)) {
      target = _dateInMonth(now.year, now.month + 1, safeDay);
    }
    return target.difference(today).inDays;
  }

  DateTime _dateInMonth(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay.clamp(1, lastDay));
  }
}
