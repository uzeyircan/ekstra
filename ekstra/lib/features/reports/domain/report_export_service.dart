import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/reports/domain/monthly_summary.dart';
import 'package:intl/intl.dart';

class ReportExportService {
  const ReportExportService();

  String monthlyCsv({
    required MonthlySummary summary,
    required double hourlyRate,
  }) {
    final rows = <List<String>>[
      ['Tarih', 'Mesai tipi', 'Saat', 'Katsayı', 'Kazanç', 'Not'],
      ...summary.entries.map((entry) {
        return [
          DateFormat('yyyy-MM-dd').format(entry.date),
          entry.overtimeType.label,
          entry.hours.toStringAsFixed(1),
          entry.multiplier.toStringAsFixed(2),
          entry.earning(hourlyRate).toStringAsFixed(2),
          entry.note,
        ];
      }),
    ];
    return _csv(rows);
  }

  String monthlyPdfText({
    required String title,
    required MonthlySummary summary,
    required double hourlyRate,
    required String formattedTotalEarnings,
  }) {
    final busiestDay = summary.busiestDay == null
        ? '-'
        : DateFormat('d MMMM yyyy', 'tr_TR').format(summary.busiestDay!.date);
    final entries = summary.entries
        .map((entry) {
          return '${DateFormat('d MMMM EEEE', 'tr_TR').format(entry.date)} | '
              '${entry.hours.toStringAsFixed(1)}s | '
              '${entry.overtimeType.label} | '
              '${entry.earning(hourlyRate).toStringAsFixed(2)} TRY';
        })
        .join('\n');

    return [
      'EKSTRA RAPOR',
      title,
      '',
      'Toplam mesai: ${summary.totalHours.toStringAsFixed(1)}s',
      'Toplam tahmini kazanç: $formattedTotalEarnings',
      'Mesai yapılan gün: ${summary.entries.length}',
      'En yoğun gün: $busiestDay',
      '',
      'Günlük kayıtlar',
      entries.isEmpty ? '-' : entries,
    ].join('\n');
  }

  String yearlyCsv({
    required List<OvertimeEntry> entries,
    required int year,
    required double hourlyRate,
  }) {
    final rows = <List<String>>[
      ['Ay', 'Toplam saat', 'Toplam kazanç'],
      for (var month = 1; month <= 12; month++)
        [
          DateFormat.MMMM('tr_TR').format(DateTime(year, month)),
          _monthHours(entries, year, month).toStringAsFixed(1),
          _monthEarnings(entries, year, month, hourlyRate).toStringAsFixed(2),
        ],
    ];
    return _csv(rows);
  }

  String yearlyPdfText({
    required List<OvertimeEntry> entries,
    required int year,
    required double hourlyRate,
    required String formattedTotalEarnings,
  }) {
    final totalHours = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.hours,
    );
    final monthRows = [
      for (var month = 1; month <= 12; month++)
        '${DateFormat.MMMM('tr_TR').format(DateTime(year, month))}: '
            '${_monthHours(entries, year, month).toStringAsFixed(1)}s | '
            '${_monthEarnings(entries, year, month, hourlyRate).toStringAsFixed(2)} TRY',
    ].join('\n');

    return [
      'EKSTRA RAPOR',
      '$year yıllık özet',
      '',
      'Toplam mesai: ${totalHours.toStringAsFixed(1)}s',
      'Toplam tahmini kazanç: $formattedTotalEarnings',
      '',
      'Ay bazlı dağılım',
      monthRows,
    ].join('\n');
  }

  String _csv(List<List<String>> rows) {
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  double _monthHours(List<OvertimeEntry> entries, int year, int month) {
    return entries
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .fold(0, (sum, entry) => sum + entry.hours);
  }

  double _monthEarnings(
    List<OvertimeEntry> entries,
    int year,
    int month,
    double hourlyRate,
  ) {
    return entries
        .where((entry) => entry.date.year == year && entry.date.month == month)
        .fold(0, (sum, entry) => sum + entry.earning(hourlyRate));
  }
}
