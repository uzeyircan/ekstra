import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/metric_card.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
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
        Text(
          '${now.year} yıllık özet',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
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
      ],
    );
  }
}

class _YearlyMonthGrid extends StatelessWidget {
  const _YearlyMonthGrid({required this.values});

  final Map<int, double> values;

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.navy2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                    color: hasValue ? AppColors.orange : AppColors.surface2,
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
