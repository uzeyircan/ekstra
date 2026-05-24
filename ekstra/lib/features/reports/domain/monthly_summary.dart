import 'package:ekstra/features/overtime/domain/overtime_entry.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalHours,
    required this.totalEarnings,
    required this.entries,
  });

  final int year;
  final int month;
  final double totalHours;
  final double totalEarnings;
  final List<OvertimeEntry> entries;

  OvertimeEntry? get busiestDay {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => b.hours.compareTo(a.hours));
    return sorted.first;
  }
}
