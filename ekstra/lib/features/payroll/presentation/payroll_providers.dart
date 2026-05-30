import 'package:ekstra/features/payroll/data/local_payroll_repository.dart';
import 'package:ekstra/features/payroll/data/local_payroll_lock_repository.dart';
import 'package:ekstra/features/payroll/domain/payroll_check.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final payrollRepositoryProvider = Provider<LocalPayrollRepository>((ref) {
  return LocalPayrollRepository(ref.watch(hiveServiceProvider));
});

final payrollLockRepositoryProvider = Provider<LocalPayrollLockRepository>((
  ref,
) {
  return LocalPayrollLockRepository(ref.watch(hiveServiceProvider));
});

final payrollCheckProvider = FutureProvider.family<PayrollCheck?, String>((
  ref,
  key,
) {
  final parts = key.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return ref.watch(payrollRepositoryProvider).get(year: year, month: month);
});

final payrollLockProvider = FutureProvider.family<PayrollLock?, String>((
  ref,
  key,
) {
  final parts = key.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return ref.watch(payrollLockRepositoryProvider).get(year: year, month: month);
});
