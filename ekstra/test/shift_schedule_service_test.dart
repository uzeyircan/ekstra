import 'package:ekstra/features/shifts/domain/shift_schedule_service.dart';
import 'package:ekstra/features/shifts/domain/shift_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const morning = ShiftTemplate(
    id: 'morning',
    name: 'Sabah',
    startTime: '08:00',
    endTime: '16:00',
    color: 0xFF2ED573,
    isEnabled: true,
  );
  const evening = ShiftTemplate(
    id: 'evening',
    name: 'Akşam',
    startTime: '16:00',
    endTime: '00:00',
    color: 0xFFFF9F43,
    isEnabled: true,
  );

  test('builds weekday assignments for a month', () {
    const service = ShiftScheduleService();

    final assignments = service.buildMonthlyAssignments(
      template: morning,
      month: DateTime(2026, 5),
      repeatType: ShiftRepeatType.weekdays,
      selectedWeekdays: const {},
    );

    expect(assignments.length, 21);
    expect(assignments.first.templateId, 'morning');
    expect(
      assignments.any((item) => item.date.weekday == DateTime.saturday),
      isFalse,
    );
  });

  test('builds selected weekday assignments', () {
    const service = ShiftScheduleService();

    final assignments = service.buildMonthlyAssignments(
      template: morning,
      month: DateTime(2026, 5),
      repeatType: ShiftRepeatType.selectedDays,
      selectedWeekdays: const {DateTime.monday},
    );

    expect(assignments.length, 4);
    expect(
      assignments.every((item) => item.date.weekday == DateTime.monday),
      isTrue,
    );
  });

  test('alternates templates by week', () {
    const service = ShiftScheduleService();

    final assignments = service.buildMonthlyAssignments(
      template: morning,
      month: DateTime(2026, 5),
      repeatType: ShiftRepeatType.alternatingWeeks,
      selectedWeekdays: const {},
      alternateTemplate: evening,
    );

    expect(assignments.first.templateId, 'morning');
    expect(assignments[7].templateId, 'evening');
    expect(assignments[14].templateId, 'morning');
  });
}
