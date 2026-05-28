class PayrollLock {
  const PayrollLock({
    required this.year,
    required this.month,
    required this.lockedAt,
    required this.note,
  });

  final int year;
  final int month;
  final DateTime lockedAt;
  final String note;

  String get key => keyFor(year: year, month: month);

  static String keyFor({required int year, required int month}) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'lockedAt': lockedAt.toIso8601String(),
      'note': note,
    };
  }

  factory PayrollLock.fromJson(Map<dynamic, dynamic> json) {
    return PayrollLock(
      year: json['year'] as int,
      month: json['month'] as int,
      lockedAt: DateTime.parse(json['lockedAt'] as String),
      note: (json['note'] as String?) ?? '',
    );
  }
}
