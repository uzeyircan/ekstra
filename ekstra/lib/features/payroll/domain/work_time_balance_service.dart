import 'package:ekstra/features/payroll/domain/work_time_balance.dart';

class WorkTimeBalanceService {
  const WorkTimeBalanceService();

  WorkTimeBalance calculate({
    required double expectedMonthlyHours,
    required double recordedOvertimeHours,
    double? actualMonthlyWorkHours,
  }) {
    if (expectedMonthlyHours <= 0) {
      return WorkTimeBalance(
        type: WorkTimeBalanceType.notConfigured,
        expectedHours: 0,
        actualHours: actualMonthlyWorkHours ?? recordedOvertimeHours,
        differenceHours: 0,
        recordedOvertimeHours: recordedOvertimeHours,
      );
    }

    final actualHours =
        actualMonthlyWorkHours ?? expectedMonthlyHours + recordedOvertimeHours;
    final difference = actualHours - expectedMonthlyHours;
    final type = difference.abs() < 0.05
        ? WorkTimeBalanceType.balanced
        : difference > 0
        ? WorkTimeBalanceType.over
        : WorkTimeBalanceType.under;

    return WorkTimeBalance(
      type: type,
      expectedHours: expectedMonthlyHours,
      actualHours: actualHours,
      differenceHours: difference,
      recordedOvertimeHours: recordedOvertimeHours,
    );
  }
}
