import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';

class LocalPayrollLockRepository {
  const LocalPayrollLockRepository(this._hive);

  final HiveService _hive;

  Future<PayrollLock?> get({required int year, required int month}) async {
    final value = _hive.payrollLocksBox.get(
      PayrollLock.keyFor(year: year, month: month),
    );
    if (value is! Map) return null;
    return PayrollLock.fromJson(value);
  }

  Future<void> save(PayrollLock lock) async {
    await _hive.payrollLocksBox.put(lock.key, lock.toJson());
    await _hive.payrollLocksBox.flush();
  }

  Future<void> unlock({required int year, required int month}) async {
    await _hive.payrollLocksBox.delete(
      PayrollLock.keyFor(year: year, month: month),
    );
    await _hive.payrollLocksBox.flush();
  }
}
