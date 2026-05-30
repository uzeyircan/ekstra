class UserSettings {
  const UserSettings({
    required this.hourlyRate,
    required this.defaultMultiplier,
    required this.currency,
    required this.isShiftEnabled,
    required this.hasCompletedOnboarding,
    required this.isDarkMode,
    required this.monthlyNetSalary,
    required this.monthlyWorkHours,
    required this.salaryDayOfMonth,
    required this.notificationsEnabled,
    required this.shiftReminderEnabled,
    required this.overtimeReminderEnabled,
    required this.salaryReminderEnabled,
    required this.monthlySummaryReminderEnabled,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      hourlyRate: 0,
      defaultMultiplier: 1.5,
      currency: 'TRY',
      isShiftEnabled: false,
      hasCompletedOnboarding: false,
      isDarkMode: true,
      monthlyNetSalary: 0,
      monthlyWorkHours: 0,
      salaryDayOfMonth: 1,
      notificationsEnabled: false,
      shiftReminderEnabled: true,
      overtimeReminderEnabled: true,
      salaryReminderEnabled: true,
      monthlySummaryReminderEnabled: true,
    );
  }

  final double hourlyRate;
  final double defaultMultiplier;
  final String currency;
  final bool isShiftEnabled;
  final bool hasCompletedOnboarding;
  final bool isDarkMode;
  final double monthlyNetSalary;
  final double monthlyWorkHours;
  final int salaryDayOfMonth;
  final bool notificationsEnabled;
  final bool shiftReminderEnabled;
  final bool overtimeReminderEnabled;
  final bool salaryReminderEnabled;
  final bool monthlySummaryReminderEnabled;

  UserSettings copyWith({
    double? hourlyRate,
    double? defaultMultiplier,
    String? currency,
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
  }) {
    return UserSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      defaultMultiplier: defaultMultiplier ?? this.defaultMultiplier,
      currency: currency ?? this.currency,
      isShiftEnabled: isShiftEnabled ?? this.isShiftEnabled,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      monthlyNetSalary: monthlyNetSalary ?? this.monthlyNetSalary,
      monthlyWorkHours: monthlyWorkHours ?? this.monthlyWorkHours,
      salaryDayOfMonth: salaryDayOfMonth ?? this.salaryDayOfMonth,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      shiftReminderEnabled: shiftReminderEnabled ?? this.shiftReminderEnabled,
      overtimeReminderEnabled:
          overtimeReminderEnabled ?? this.overtimeReminderEnabled,
      salaryReminderEnabled:
          salaryReminderEnabled ?? this.salaryReminderEnabled,
      monthlySummaryReminderEnabled:
          monthlySummaryReminderEnabled ?? this.monthlySummaryReminderEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hourlyRate': hourlyRate,
      'defaultMultiplier': defaultMultiplier,
      'currency': currency,
      'isShiftEnabled': isShiftEnabled,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isDarkMode': isDarkMode,
      'monthlyNetSalary': monthlyNetSalary,
      'monthlyWorkHours': monthlyWorkHours,
      'salaryDayOfMonth': salaryDayOfMonth,
      'notificationsEnabled': notificationsEnabled,
      'shiftReminderEnabled': shiftReminderEnabled,
      'overtimeReminderEnabled': overtimeReminderEnabled,
      'salaryReminderEnabled': salaryReminderEnabled,
      'monthlySummaryReminderEnabled': monthlySummaryReminderEnabled,
    };
  }

  factory UserSettings.fromJson(Map<dynamic, dynamic> json) {
    final hasStoredSetupData =
        ((json['hourlyRate'] as num?)?.toDouble() ?? 0) > 0;

    return UserSettings(
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      defaultMultiplier: (json['defaultMultiplier'] as num?)?.toDouble() ?? 1.5,
      currency: (json['currency'] as String?) ?? 'TRY',
      isShiftEnabled: (json['isShiftEnabled'] as bool?) ?? false,
      hasCompletedOnboarding:
          (json['hasCompletedOnboarding'] as bool?) ?? hasStoredSetupData,
      isDarkMode: (json['isDarkMode'] as bool?) ?? true,
      monthlyNetSalary: (json['monthlyNetSalary'] as num?)?.toDouble() ?? 0,
      monthlyWorkHours: (json['monthlyWorkHours'] as num?)?.toDouble() ?? 0,
      salaryDayOfMonth: (json['salaryDayOfMonth'] as num?)?.toInt() ?? 1,
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? false,
      shiftReminderEnabled: (json['shiftReminderEnabled'] as bool?) ?? true,
      overtimeReminderEnabled:
          (json['overtimeReminderEnabled'] as bool?) ?? true,
      salaryReminderEnabled: (json['salaryReminderEnabled'] as bool?) ?? true,
      monthlySummaryReminderEnabled:
          (json['monthlySummaryReminderEnabled'] as bool?) ?? true,
    );
  }
}
