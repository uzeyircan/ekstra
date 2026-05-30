import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/settings/data/local_settings_repository.dart';
import 'package:ekstra/features/settings/domain/settings_repository.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('HiveService must be overridden in main.');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(hiveServiceProvider));
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<UserSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<UserSettings> build() => _repository.get();

  Future<void> save(UserSettings settings) async {
    await _repository.save(settings);
    state = AsyncData(settings);
  }

  Future<void> updateSettings({
    double? hourlyRate,
    double? defaultMultiplier,
    bool? isShiftEnabled,
    bool? hasCompletedOnboarding,
    bool? isDarkMode,
    double? monthlyNetSalary,
    double? monthlyWorkHours,
    int? salaryDayOfMonth,
    bool? notificationsEnabled,
    bool? shiftReminderEnabled,
    bool? overtimeReminderEnabled,
    bool? salaryReminderEnabled,
    bool? monthlySummaryReminderEnabled,
  }) async {
    final current = state.value ?? await _repository.get();
    await save(
      current.copyWith(
        hourlyRate: hourlyRate,
        defaultMultiplier: defaultMultiplier,
        isShiftEnabled: isShiftEnabled,
        hasCompletedOnboarding: hasCompletedOnboarding,
        isDarkMode: isDarkMode,
        monthlyNetSalary: monthlyNetSalary,
        monthlyWorkHours: monthlyWorkHours,
        salaryDayOfMonth: salaryDayOfMonth,
        notificationsEnabled: notificationsEnabled,
        shiftReminderEnabled: shiftReminderEnabled,
        overtimeReminderEnabled: overtimeReminderEnabled,
        salaryReminderEnabled: salaryReminderEnabled,
        monthlySummaryReminderEnabled: monthlySummaryReminderEnabled,
      ),
    );
  }
}
