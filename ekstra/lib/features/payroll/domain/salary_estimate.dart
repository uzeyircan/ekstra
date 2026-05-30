class SalaryEstimate {
  const SalaryEstimate({
    required this.estimatedTotalEarnings,
    required this.normalWorkEarnings,
    required this.overtimeEarnings,
    required this.totalOvertimeHours,
    required this.baseWorkHours,
    required this.hourlyRate,
    required this.defaultMultiplier,
  });

  final double estimatedTotalEarnings;
  final double normalWorkEarnings;
  final double overtimeEarnings;
  final double totalOvertimeHours;
  final double baseWorkHours;
  final double hourlyRate;
  final double defaultMultiplier;
}
