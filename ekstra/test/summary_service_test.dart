import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monthly summary calculates hours and earnings', () {
    final entries = [
      OvertimeEntry(
        id: '1',
        date: DateTime(2026, 5, 1),
        hours: 3,
        note: '',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
      OvertimeEntry(
        id: '2',
        date: DateTime(2026, 5, 2),
        hours: 2,
        note: '',
        overtimeType: OvertimeType.holiday,
        multiplier: 2,
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
    ];

    const service = SummaryService();
    final summary = service.monthly(
      entries: entries,
      year: 2026,
      month: 5,
      hourlyRate: 100,
    );

    expect(summary.totalHours, 5);
    expect(summary.totalEarnings, 850);
    expect(summary.busiestDay?.id, '1');
  });

  test('monthly hours by day fills all days in month', () {
    final entries = [
      OvertimeEntry(
        id: '1',
        date: DateTime(2026, 5, 24),
        hours: 4,
        note: '',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        createdAt: DateTime(2026, 5, 24),
        updatedAt: DateTime(2026, 5, 24),
      ),
    ];

    const service = SummaryService();
    final result = service.monthlyHoursByDay(
      entries: entries,
      year: 2026,
      month: 5,
    );

    expect(result.length, 31);
    expect(result[24], 4);
    expect(result[1], 0);
  });

  test('entry earning uses stored hourly rate snapshot when available', () {
    final entry = OvertimeEntry(
      id: '1',
      date: DateTime(2026, 5, 24),
      hours: 2,
      note: '',
      overtimeType: OvertimeType.normal,
      multiplier: 1.5,
      hourlyRateSnapshot: 200,
      createdAt: DateTime(2026, 5, 24),
      updatedAt: DateTime(2026, 5, 24),
    );

    expect(entry.earning(500), 600);
  });
}
