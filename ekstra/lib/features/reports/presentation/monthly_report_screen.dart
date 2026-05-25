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

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(overtimeEntriesProvider).value ?? [];
    final settings = ref.watch(settingsControllerProvider).value;
    final now = DateTime.now();
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');
    final hourlyRate = settings?.hourlyRate ?? 0;
    const service = SummaryService();
    final summary = service.monthly(
      entries: entries,
      year: now.year,
      month: now.month,
      hourlyRate: hourlyRate,
    );
    final dailyHours = service.monthlyHoursByDay(
      entries: entries,
      year: now.year,
      month: now.month,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          DateFormat('MMMM yyyy', 'tr_TR').format(now),
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
              label: 'Toplam saat',
              value: '${summary.totalHours.toStringAsFixed(1)}s',
              icon: Icons.timer_rounded,
              infoTitle: 'Aylık toplam saat',
              infoMessage:
                  'Seçili ay içindeki tüm mesai kayıtlarının saat toplamıdır.',
            ),
            MetricCard(
              label: 'Toplam kazanç',
              value: currency.format(summary.totalEarnings),
              icon: Icons.payments_rounded,
              accent: AppColors.green,
              infoTitle: 'Aylık toplam kazanç',
              infoMessage:
                  'Seçili ay içindeki tüm kayıtların tahmini kazanç toplamıdır. Formül: saat × saatlik ücret × katsayı.',
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
                      'Ay içi yoğunluk',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const InfoTooltipButton(
                    title: 'Ay içi yoğunluk',
                    message:
                        'Her çubuk ayın bir gününde kaydedilen toplam mesai saatini gösterir. En uzun çubuk, ay içindeki en yüksek günlük mesaiye göre ölçeklenir.',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Günlere göre mesai saatlerinin dağılımı',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _DailyBars(values: dailyHours),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En yoğun gün: ${summary.busiestDay == null ? '-' : DateFormat('d MMMM', 'tr_TR').format(summary.busiestDay!.date)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...summary.entries.map(
          (entry) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.surface2,
              child: Icon(Icons.bolt_rounded, color: AppColors.orange),
            ),
            title: Text(DateFormat('d MMMM EEEE', 'tr_TR').format(entry.date)),
            subtitle: Text(entry.overtimeType.label),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.hours.toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  currency.format(entry.earning(hourlyRate)),
                  style: const TextStyle(color: AppColors.green),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.values});

  final Map<int, double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<double>(
      1,
      (max, value) => value > max ? value : max,
    );

    return SizedBox(
      height: 156,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.entries.map((item) {
          final hasValue = item.value > 0;
          final heightFactor = (item.value / maxValue).clamp(0.06, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: hasValue
                                ? AppColors.orange
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (item.key == 1 || item.key % 5 == 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${item.key}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ] else
                    const SizedBox(height: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
