import 'dart:convert';
import 'dart:typed_data';

import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/reports/domain/monthly_summary.dart';
import 'package:ekstra/features/reports/domain/report_export_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportFileExportService {
  const ReportFileExportService({
    this.textExportService = const ReportExportService(),
  });

  final ReportExportService textExportService;

  Future<void> shareMonthlyPdf({
    required MonthlySummary summary,
    required double hourlyRate,
    required String formattedTotalEarnings,
  }) async {
    final title = DateFormat(
      'MMMM yyyy',
      'tr_TR',
    ).format(DateTime(summary.year, summary.month));
    final bytes = await _buildPdf(
      title: '$title aylık rapor',
      lines: textExportService
          .monthlyPdfText(
            title: title,
            summary: summary,
            hourlyRate: hourlyRate,
            formattedTotalEarnings: formattedTotalEarnings,
          )
          .split('\n'),
    );
    await _shareBytes(
      bytes: bytes,
      fileName: 'ekstra_${summary.year}_${_two(summary.month)}_aylik_rapor.pdf',
      mimeType: 'application/pdf',
      text: 'EKSTRA aylık mesai raporu',
    );
  }

  Future<void> shareMonthlyCsv({
    required MonthlySummary summary,
    required double hourlyRate,
  }) async {
    final csv = textExportService.monthlyCsv(
      summary: summary,
      hourlyRate: hourlyRate,
    );
    await _shareBytes(
      bytes: Uint8List.fromList(utf8.encode(csv)),
      fileName: 'ekstra_${summary.year}_${_two(summary.month)}_aylik_rapor.csv',
      mimeType: 'text/csv',
      text: 'EKSTRA aylık CSV raporu',
    );
  }

  Future<void> shareYearlyPdf({
    required List<OvertimeEntry> entries,
    required int year,
    required double hourlyRate,
    required String formattedTotalEarnings,
  }) async {
    final bytes = await _buildPdf(
      title: '$year yıllık rapor',
      lines: textExportService
          .yearlyPdfText(
            entries: entries,
            year: year,
            hourlyRate: hourlyRate,
            formattedTotalEarnings: formattedTotalEarnings,
          )
          .split('\n'),
    );
    await _shareBytes(
      bytes: bytes,
      fileName: 'ekstra_${year}_yillik_rapor.pdf',
      mimeType: 'application/pdf',
      text: 'EKSTRA yıllık mesai raporu',
    );
  }

  Future<void> shareYearlyCsv({
    required List<OvertimeEntry> entries,
    required int year,
    required double hourlyRate,
  }) async {
    final csv = textExportService.yearlyCsv(
      entries: entries,
      year: year,
      hourlyRate: hourlyRate,
    );
    await _shareBytes(
      bytes: Uint8List.fromList(utf8.encode(csv)),
      fileName: 'ekstra_${year}_yillik_rapor.csv',
      mimeType: 'text/csv',
      text: 'EKSTRA yıllık CSV raporu',
    );
  }

  Future<Uint8List> _buildPdf({
    required String title,
    required List<String> lines,
  }) async {
    final document = pw.Document();
    final generatedAt = DateFormat(
      'd MMMM yyyy HH:mm',
      'tr_TR',
    ).format(DateTime.now());

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'EKSTRA',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(title, style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Oluşturulma: $generatedAt',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          ...lines
              .where((line) => line.trim().isNotEmpty)
              .map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
                ),
              ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Not: Bu rapor kullanıcı kayıtlarına göre tahmini olarak hazırlanır.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> _shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
  }) {
    return Share.shareXFiles([
      XFile.fromData(bytes, name: fileName, mimeType: mimeType),
    ], text: text);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
