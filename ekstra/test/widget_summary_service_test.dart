import 'package:ekstra/features/dashboard/domain/widget_summary_service.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget summary combines shift, overtime, earnings and payday', () {
    final now = DateTime(2026, 5, 28, 9);
    final settings = UserSettings.defaults().copyWith(
      hourlyRate: 200,
      monthlyNetSalary: 30000,
      monthlyWorkHours: 180,
      salaryDayOfMonth: 31,
    );
    final entries = [
      OvertimeEntry(
        id: '2026-05-28',
        date: DateTime(2026, 5, 28),
        hours: 2,
        note: '',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        createdAt: now,
        updatedAt: now,
      ),
    ];
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

    const service = WidgetSummaryService();
    final summary = service.build(
      now: now,
      settings: settings,
      entries: entries,
      assignments: assignments,
    );

    expect(summary.todayShiftLabel, 'Sabah');
    expect(summary.todayShiftTimeRange, '08:00-16:00');
    expect(summary.monthlyOvertimeHours, 2);
    expect(summary.monthlyEstimatedEarnings, 30600);
    expect(summary.daysUntilSalaryDay, 3);
  });

  test('widget summary moves payday to next month when passed', () {
    final now = DateTime(2026, 5, 28);
    final settings = UserSettings.defaults().copyWith(salaryDayOfMonth: 15);

    const service = WidgetSummaryService();
    final summary = service.build(
      now: now,
      settings: settings,
      entries: const [],
      assignments: const [],
    );

    expect(summary.daysUntilSalaryDay, 18);
  });
}
