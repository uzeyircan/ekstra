import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/payroll/domain/salary_estimate.dart';

class SalaryEstimateService {
  const SalaryEstimateService();

  SalaryEstimate calculate({
    required Iterable<OvertimeEntry> overtimeEntries,
    required double monthlyNetSalary,
    required double hourlyRate,
    required double defaultMultiplier,
    required double monthlyWorkHours,
  }) {
    final totalOvertimeHours = overtimeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final overtimeEarnings = overtimeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.earning(hourlyRate),
    );
    final normalWorkEarnings = monthlyNetSalary > 0
        ? monthlyNetSalary
        : monthlyWorkHours * hourlyRate;

    return SalaryEstimate(
      estimatedTotalEarnings: normalWorkEarnings + overtimeEarnings,
      normalWorkEarnings: normalWorkEarnings,
      overtimeEarnings: overtimeEarnings,
      totalOvertimeHours: totalOvertimeHours,
      baseWorkHours: monthlyWorkHours,
      hourlyRate: hourlyRate,
      defaultMultiplier: defaultMultiplier,
    );
  }
}
