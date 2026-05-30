import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/reports/domain/monthly_summary.dart';
import 'package:ekstra/features/reports/domain/report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  test('monthly CSV includes entry rows', () {
    final entry = OvertimeEntry(
      id: '2026-05-24',
      date: DateTime(2026, 5, 24),
      hours: 2,
      note: 'Test',
      overtimeType: OvertimeType.normal,
      multiplier: 1.5,
      createdAt: DateTime(2026, 5, 24),
      updatedAt: DateTime(2026, 5, 24),
    );
    final summary = MonthlySummary(
      year: 2026,
      month: 5,
      totalHours: 2,
      totalEarnings: 300,
      entries: [entry],
    );

    const service = ReportExportService();
    final csv = service.monthlyCsv(summary: summary, hourlyRate: 100);

    expect(csv, contains('Tarih,Mesai tipi,Saat'));
    expect(csv, contains('2026-05-24'));
    expect(csv, contains('300.00'));
  });

  test('yearly PDF text includes totals and months', () {
    final entry = OvertimeEntry(
      id: '2026-05-24',
      date: DateTime(2026, 5, 24),
      hours: 2,
      note: '',
      overtimeType: OvertimeType.normal,
      multiplier: 1.5,
      createdAt: DateTime(2026, 5, 24),
      updatedAt: DateTime(2026, 5, 24),
    );

    const service = ReportExportService();
    final text = service.yearlyPdfText(
      entries: [entry],
      year: 2026,
      hourlyRate: 100,
      formattedTotalEarnings: 'TRY 300,00',
    );

    expect(text, contains('2026 yıllık özet'));
    expect(text, contains('Toplam mesai: 2.0s'));
    expect(text, contains('Mayıs'));
  });
}
