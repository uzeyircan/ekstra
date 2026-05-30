class WidgetSummary {
  const WidgetSummary({
    required this.todayShiftLabel,
    required this.todayShiftTimeRange,
    required this.monthlyOvertimeHours,
    required this.monthlyEstimatedEarnings,
    required this.daysUntilSalaryDay,
    required this.generatedAt,
  });

  final String todayShiftLabel;
  final String todayShiftTimeRange;
  final double monthlyOvertimeHours;
  final double monthlyEstimatedEarnings;
  final int daysUntilSalaryDay;
  final DateTime generatedAt;

  bool get hasTodayShift => todayShiftLabel.isNotEmpty;
}
