import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';

class WorkRhythm {
  const WorkRhythm({
    required this.projectedMonthlyEarnings,
    required this.averageHoursPerEntry,
    required this.activeStreakDays,
    required this.busiestDay,
  });

  final double projectedMonthlyEarnings;
  final double averageHoursPerEntry;
  final int activeStreakDays;
  final OvertimeEntry? busiestDay;
}

class WorkRhythmService {
  const WorkRhythmService();

  WorkRhythm calculate({
    required List<OvertimeEntry> entries,
    required DateTime now,
    required double hourlyRate,
  }) {
    const summaryService = SummaryService();
    final monthEntries = entries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList();
    final totalHours = summaryService.totalHours(monthEntries);
    final totalEarnings = summaryService.totalEarnings(
      monthEntries,
      hourlyRate,
    );
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projectedMonthlyEarnings = now.day == 0
        ? totalEarnings
        : (totalEarnings / now.day) * daysInMonth;

    final averageHoursPerEntry = monthEntries.isEmpty
        ? 0.0
        : totalHours / monthEntries.length;

    return WorkRhythm(
      projectedMonthlyEarnings: projectedMonthlyEarnings.toDouble(),
      averageHoursPerEntry: averageHoursPerEntry,
      activeStreakDays: _activeStreakDays(monthEntries, now),
      busiestDay: _busiestDay(monthEntries),
    );
  }

  int _activeStreakDays(List<OvertimeEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;
    final days = entries.map((entry) => DateKey.fromDate(entry.date)).toSet();
    var streak = 0;
    var cursor = DateKey.onlyDate(now);
    while (days.contains(DateKey.fromDate(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  OvertimeEntry? _busiestDay(List<OvertimeEntry> entries) {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => b.hours.compareTo(a.hours));
    return sorted.first;
  }
}
