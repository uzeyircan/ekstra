import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings persists hourly rate and multiplier', () {
    final settings = UserSettings.defaults().copyWith(
      hourlyRate: 125,
      defaultMultiplier: 2,
      monthlyNetSalary: 30000,
      monthlyWorkHours: 180,
      salaryDayOfMonth: 15,
      notificationsEnabled: true,
      shiftReminderEnabled: false,
    );

    final restored = UserSettings.fromJson(settings.toJson());

    expect(restored.hourlyRate, 125);
    expect(restored.defaultMultiplier, 2);
    expect(restored.monthlyNetSalary, 30000);
    expect(restored.monthlyWorkHours, 180);
    expect(restored.salaryDayOfMonth, 15);
    expect(restored.notificationsEnabled, isTrue);
    expect(restored.shiftReminderEnabled, isFalse);
  });

  test('old saved setup data is treated as completed onboarding', () {
    final restored = UserSettings.fromJson({
      'hourlyRate': 125,
      'defaultMultiplier': 1.5,
      'currency': 'TRY',
      'isShiftEnabled': false,
      'isDarkMode': true,
    });

    expect(restored.hasCompletedOnboarding, isTrue);
  });

  test('old backup tracking date field is ignored', () {
    final restored = UserSettings.fromJson({
      'hourlyRate': 125,
      'defaultMultiplier': 1.5,
      'currency': 'TRY',
      'isShiftEnabled': false,
      'isDarkMode': true,
      'trackingStartDate': '2026-05-24T00:00:00.000',
    });

    expect(restored.hourlyRate, 125);
  });
}
