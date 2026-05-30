import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/monetization/domain/monetized_feature.dart';
import 'package:ekstra/features/monetization/presentation/monetization_gate.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/reports/domain/report_file_export_service.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/export_action_panel.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/metric_card.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class YearlyReportScreen extends ConsumerWidget {
  const YearlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(overtimeEntriesProvider).value ?? [];
    final settings = ref.watch(settingsControllerProvider).value;
    final hourlyRate = settings?.hourlyRate ?? 0;
    final now = DateTime.now();
    const service = SummaryService();
    const fileExportService = ReportFileExportService();
    final yearEntries = entries
        .where((entry) => entry.date.year == now.year)
        .toList();
    final monthMap = service.yearlyHoursByMonth(entries, now.year);
    final totalHours = service.totalHours(yearEntries);
    final totalEarnings = service.totalEarnings(yearEntries, hourlyRate);
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _YearlyHero(
          year: now.year,
          earnings: currency.format(totalEarnings),
          totalHours: totalHours,
          activeMonths: monthMap.values.where((hours) => hours > 0).length,
        ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.03, end: 0),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            MetricCard(
              label: 'Yıllık mesai',
              value: '${totalHours.toStringAsFixed(1)}s',
              icon: Icons.av_timer_rounded,
              infoTitle: 'Yıllık mesai',
              infoMessage:
                  'Bu yıl içinde kaydettiğin tüm mesai kayıtlarının saat toplamıdır.',
            ),
            MetricCard(
              label: 'Yıllık kazanç',
              value: currency.format(totalEarnings),
              icon: Icons.savings_rounded,
              accent: AppColors.green,
              infoTitle: 'Yıllık kazanç',
              infoMessage:
                  'Bu yıl içindeki tüm mesai kayıtlarının tahmini kazanç toplamıdır.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ay bazlı dağılım',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const InfoTooltipButton(
                    title: 'Ay bazlı dağılım',
                    message:
                        'Her satır ilgili ayda kaydedilen toplam mesai saatini gösterir. Doluluk oranı, yıl içindeki en yüksek mesai yapılan aya göre ölçeklenir.',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Yıl içindeki mesai yoğunluğunu ay ay gör.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _YearlyMonthGrid(values: monthMap),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ExportActionPanel(
          title: 'Yıllık dosya',
          subtitle: 'Tüm yılın mesai özetini PDF veya CSV olarak paylaş.',
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final canContinue = await requireRewardedAdOrPro(
                  context: context,
                  ref: ref,
                  feature: MonetizedFeature.pdfExport,
                  title: 'Yıllık PDF raporu',
                  message: 'Yıllık PDF dosyası oluşturulacak.',
                );
                if (!canContinue || !context.mounted) return;
                await fileExportService.shareYearlyPdf(
                  entries: yearEntries,
                  year: now.year,
                  hourlyRate: hourlyRate,
                  formattedTotalEarnings: currency.format(totalEarnings),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yıllık PDF raporu hazırlandı.'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final canContinue = await requireRewardedAdOrPro(
                  context: context,
                  ref: ref,
                  feature: MonetizedFeature.excelExport,
                  title: 'Yıllık CSV raporu',
                  message:
                      'Excel ile açılabilen yıllık CSV çıktısı oluşturulacak.',
                );
                if (!canContinue || !context.mounted) return;
                await fileExportService.shareYearlyCsv(
                  entries: yearEntries,
                  year: now.year,
                  hourlyRate: hourlyRate,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yıllık CSV raporu hazırlandı.'),
                  ),
                );
              },
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('CSV'),
            ),
          ],
        ),
        if (yearEntries.isEmpty) ...[
          const SizedBox(height: 16),
          const _YearlyEmptyState(),
        ],
      ],
    );
  }
}

class _YearlyHero extends StatelessWidget {
  const _YearlyHero({
    required this.year,
    required this.earnings,
    required this.totalHours,
    required this.activeMonths,
  });

  final int year;
  final String earnings;
  final double totalHours;
  final int activeMonths;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173456), Color(0xFF0B1728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$year yıllık özet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'Yıl içinde takip edilen ekstra gelir',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            earnings,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.green,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _YearlyPill(
                label: 'Saat',
                value: '${totalHours.toStringAsFixed(1)}s',
              ),
              const SizedBox(width: 8),
              _YearlyPill(label: 'Aktif ay', value: '$activeMonths'),
            ],
          ),
        ],
      ),
    );
  }
}

class _YearlyPill extends StatelessWidget {
  const _YearlyPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.navy2.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearlyEmptyState extends StatelessWidget {
  const _YearlyEmptyState();

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bu yıl henüz mesai yok',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Kayıt ekledikçe yıllık dağılım burada güçlenecek.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearlyMonthGrid extends StatelessWidget {
  const _YearlyMonthGrid({required this.values});

  final Map<int, double> values;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHours = values.values.fold<double>(
      1,
      (max, value) => value > max ? value : max,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: values.entries.map((item) {
        final monthName = DateFormat.MMM(
          'tr_TR',
        ).format(DateTime(DateTime.now().year, item.key));
        final ratio = (item.value / maxHours).clamp(0.0, 1.0);
        final hasValue = item.value > 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.navy2 : const Color(0xFFF4F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasValue
                  ? AppColors.orange.withValues(alpha: 0.28)
                  : isDark
                  ? AppColors.border
                  : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  monthName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: ratio,
                    color: hasValue ? AppColors.green : AppColors.surface2,
                    backgroundColor: AppColors.surface2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text(
                  '${item.value.toStringAsFixed(1)}s',
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
