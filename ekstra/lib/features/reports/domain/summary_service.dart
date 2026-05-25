import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/reports/domain/monthly_summary.dart';

class SummaryService {
  const SummaryService();

  double totalHours(Iterable<OvertimeEntry> entries) {
    return entries.fold(0, (sum, entry) => sum + entry.hours);
  }

  double totalEarnings(Iterable<OvertimeEntry> entries, double hourlyRate) {
    return entries.fold(0, (sum, entry) => sum + entry.earning(hourlyRate));
  }

  MonthlySummary monthly({
    required List<OvertimeEntry> entries,
    required int year,
    required int month,
    required double hourlyRate,
  }) {
    final filtered =
        entries
            .where(
              (entry) => entry.date.year == year && entry.date.month == month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return MonthlySummary(
      year: year,
      month: month,
      totalHours: totalHours(filtered),
      totalEarnings: totalEarnings(filtered, hourlyRate),
      entries: filtered,
    );
  }

  Map<int, double> yearlyHoursByMonth(List<OvertimeEntry> entries, int year) {
    final result = {for (var month = 1; month <= 12; month++) month: 0.0};
    for (final entry in entries.where((entry) => entry.date.year == year)) {
      result[entry.date.month] = (result[entry.date.month] ?? 0) + entry.hours;
    }
    return result;
  }

  Map<int, double> monthlyHoursByDay({
    required List<OvertimeEntry> entries,
    required int year,
    required int month,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = {for (var day = 1; day <= daysInMonth; day++) day: 0.0};
    for (final entry in entries.where(
      (entry) => entry.date.year == year && entry.date.month == month,
    )) {
      result[entry.date.day] = (result[entry.date.day] ?? 0) + entry.hours;
    }
    return result;
  }
}
