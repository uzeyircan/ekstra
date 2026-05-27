import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/payroll/domain/payroll_check.dart';

class LocalPayrollRepository {
  const LocalPayrollRepository(this._hive);

  final HiveService _hive;

  Future<PayrollCheck?> get({required int year, required int month}) async {
    final value = _hive.payrollChecksBox.get(
      PayrollCheck.keyFor(year: year, month: month),
    );
    if (value is! Map) return null;
    return PayrollCheck.fromJson(value);
  }

  Future<void> save(PayrollCheck check) async {
    await _hive.payrollChecksBox.put(check.key, check.toJson());
    await _hive.payrollChecksBox.flush();
  }
}
