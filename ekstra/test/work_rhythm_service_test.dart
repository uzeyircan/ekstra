import 'package:ekstra/features/dashboard/domain/work_rhythm.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('work rhythm calculates projection, average and streak', () {
    final now = DateTime(2026, 5, 3);
    final entries = [
      _entry('1', DateTime(2026, 5, 3), 2),
      _entry('2', DateTime(2026, 5, 2), 4),
      _entry('3', DateTime(2026, 5, 1), 3),
    ];

    const service = WorkRhythmService();
    final rhythm = service.calculate(
      entries: entries,
      now: now,
      hourlyRate: 100,
    );

    expect(rhythm.activeStreakDays, 3);
    expect(rhythm.averageHoursPerEntry, 3);
    expect(rhythm.projectedMonthlyEarnings, 13950);
    expect(rhythm.busiestDay?.id, '2');
  });
}

OvertimeEntry _entry(String id, DateTime date, double hours) {
  return OvertimeEntry(
    id: id,
    date: date,
    hours: hours,
    note: '',
    overtimeType: OvertimeType.normal,
    multiplier: 1.5,
    createdAt: date,
    updatedAt: date,
  );
}
