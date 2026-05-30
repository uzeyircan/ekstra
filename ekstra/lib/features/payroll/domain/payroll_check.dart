class PayrollCheck {
  const PayrollCheck({
    required this.year,
    required this.month,
    required this.payrollHours,
    required this.payrollEarnings,
    required this.note,
    required this.updatedAt,
  });

  final int year;
  final int month;
  final double payrollHours;
  final double payrollEarnings;
  final String note;
  final DateTime updatedAt;

  String get key => keyFor(year: year, month: month);

  static String keyFor({required int year, required int month}) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'payrollHours': payrollHours,
      'payrollEarnings': payrollEarnings,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PayrollCheck.fromJson(Map<dynamic, dynamic> json) {
    return PayrollCheck(
      year: json['year'] as int,
      month: json['month'] as int,
      payrollHours: (json['payrollHours'] as num).toDouble(),
      payrollEarnings: (json['payrollEarnings'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
