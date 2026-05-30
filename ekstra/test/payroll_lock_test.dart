import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payroll lock key is stable by year and month', () {
    expect(PayrollLock.keyFor(year: 2026, month: 5), '2026-05');
    expect(PayrollLock.keyFor(year: 2026, month: 12), '2026-12');
  });

  test('payroll lock serializes and restores', () {
    final lock = PayrollLock(
      year: 2026,
      month: 5,
      lockedAt: DateTime(2026, 5, 27, 12),
      note: 'Bordro kontrol edildi',
    );

    final restored = PayrollLock.fromJson(lock.toJson());

    expect(restored.key, '2026-05');
    expect(restored.note, 'Bordro kontrol edildi');
    expect(restored.lockedAt, DateTime(2026, 5, 27, 12));
  });
}
