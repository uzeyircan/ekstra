import 'package:ekstra/features/payroll/domain/work_time_balance.dart';
import 'package:ekstra/features/payroll/domain/work_time_balance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'work time balance reports estimated overtime from overtime records',
    () {
      const service = WorkTimeBalanceService();

      final balance = service.calculate(
        expectedMonthlyHours: 180,
        recordedOvertimeHours: 7,
      );

      expect(balance.type, WorkTimeBalanceType.over);
      expect(balance.expectedHours, 180);
      expect(balance.actualHours, 187);
      expect(balance.differenceHours, 7);
    },
  );

  test(
    'work time balance supports under work when actual hours are provided',
    () {
      const service = WorkTimeBalanceService();

      final balance = service.calculate(
        expectedMonthlyHours: 180,
        recordedOvertimeHours: 0,
        actualMonthlyWorkHours: 177,
      );

      expect(balance.type, WorkTimeBalanceType.under);
      expect(balance.absoluteDifferenceHours, 3);
    },
  );

  test('work time balance asks for setup when expected hours are missing', () {
    const service = WorkTimeBalanceService();

    final balance = service.calculate(
      expectedMonthlyHours: 0,
      recordedOvertimeHours: 5,
    );

    expect(balance.type, WorkTimeBalanceType.notConfigured);
  });
}
