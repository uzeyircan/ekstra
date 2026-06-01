enum DayStatusType {
  annualLeave('Yıllık izin'),
  sickLeave('Raporlu'),
  excuseLeave('Mazeret izni'),
  unpaidLeave('Ücretsiz izin'),
  publicHoliday('Resmi tatil'),
  absent('İşe gitmedi'),
  other('Diğer');

  const DayStatusType(this.label);

  final String label;

  static DayStatusType fromName(String value) {
    return DayStatusType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DayStatusType.other,
    );
  }
}
