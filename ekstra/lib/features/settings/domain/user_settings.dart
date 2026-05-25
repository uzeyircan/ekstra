class UserSettings {
  const UserSettings({
    required this.hourlyRate,
    required this.defaultMultiplier,
    required this.currency,
    required this.isShiftEnabled,
    required this.hasCompletedOnboarding,
    required this.isDarkMode,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      hourlyRate: 0,
      defaultMultiplier: 1.5,
      currency: 'TRY',
      isShiftEnabled: false,
      hasCompletedOnboarding: false,
      isDarkMode: true,
    );
  }

  final double hourlyRate;
  final double defaultMultiplier;
  final String currency;
  final bool isShiftEnabled;
  final bool hasCompletedOnboarding;
  final bool isDarkMode;

  UserSettings copyWith({
    double? hourlyRate,
    double? defaultMultiplier,
    String? currency,
    bool? isShiftEnabled,
    bool? hasCompletedOnboarding,
    bool? isDarkMode,
  }) {
    return UserSettings(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      defaultMultiplier: defaultMultiplier ?? this.defaultMultiplier,
      currency: currency ?? this.currency,
      isShiftEnabled: isShiftEnabled ?? this.isShiftEnabled,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isDarkMode: isDarkMode ?? this.isDarkMode,
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
    );
  }
}
