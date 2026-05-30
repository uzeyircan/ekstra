import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/payroll/domain/salary_estimate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salary estimate combines net salary and overtime earnings', () {
    final entries = [
      OvertimeEntry(
        id: '2026-05-01',
        date: DateTime(2026, 5, 1),
        hours: 3,
        note: '',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        hourlyRateSnapshot: 200,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
      OvertimeEntry(
        id: '2026-05-02',
        date: DateTime(2026, 5, 2),
        hours: 2,
        note: '',
        overtimeType: OvertimeType.holiday,
        multiplier: 2,
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
    ];

    const service = SalaryEstimateService();
    final estimate = service.calculate(
      overtimeEntries: entries,
      monthlyNetSalary: 30000,
      hourlyRate: 100,
      defaultMultiplier: 1.5,
      monthlyWorkHours: 180,
    );

    expect(estimate.normalWorkEarnings, 30000);
    expect(estimate.overtimeEarnings, 1300);
    expect(estimate.estimatedTotalEarnings, 31300);
    expect(estimate.totalOvertimeHours, 5);
  });

  test('salary estimate falls back to monthly hours times hourly rate', () {
    const service = SalaryEstimateService();
    final estimate = service.calculate(
      overtimeEntries: const [],
      monthlyNetSalary: 0,
      hourlyRate: 150,
      defaultMultiplier: 1.5,
      monthlyWorkHours: 200,
    );

    expect(estimate.normalWorkEarnings, 30000);
    expect(estimate.estimatedTotalEarnings, 30000);
  });
}
