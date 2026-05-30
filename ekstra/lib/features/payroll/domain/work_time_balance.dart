enum WorkTimeBalanceType { notConfigured, balanced, over, under }

class WorkTimeBalance {
  const WorkTimeBalance({
    required this.type,
    required this.expectedHours,
    required this.actualHours,
    required this.differenceHours,
    required this.recordedOvertimeHours,
  });

  final WorkTimeBalanceType type;
  final double expectedHours;
  final double actualHours;
  final double differenceHours;
  final double recordedOvertimeHours;

  double get absoluteDifferenceHours => differenceHours.abs();
}
