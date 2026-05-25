import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/dashboard/domain/work_rhythm.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/presentation/overtime_entry_sheet.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openSheet(
    BuildContext context,
    DateTime date,
    List<OvertimeEntry> entries,
    UserSettings settings,
  ) {
    final entry = entries
        .where((item) => DateKey.isSameDay(item.date, date))
        .firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) =>
          OvertimeEntrySheet(date: date, entry: entry, settings: settings),
    );
  }

  Future<void> _quickAdd(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
    double hours,
  ) async {
    await ref
        .read(overtimeEntriesProvider.notifier)
        .addQuickHours(
          date: DateTime.now(),
          hours: hours,
          multiplier: settings.defaultMultiplier,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bugüne +${hours.toStringAsFixed(0)}s eklendi')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(overtimeEntriesProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final now = DateTime.now();

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('$error')),
      data: (entries) {
        final settings = settingsAsync.value;
        if (settings == null) {
          return const Center(child: CircularProgressIndicator());
        }
        const summaryService = SummaryService();
        final month = summaryService.monthly(
          entries: entries,
          year: now.year,
          month: now.month,
          hourlyRate: settings.hourlyRate,
        );
        final yearEntries = entries
            .where((entry) => entry.date.year == now.year)
            .toList();
        final yearHours = summaryService.totalHours(yearEntries);
        final yearEarnings = summaryService.totalEarnings(
          yearEntries,
          settings.hourlyRate,
        );
        final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');
        final todayEntries = entries
            .where((entry) => DateKey.isSameDay(entry.date, now))
            .toList();
        final todayHours = summaryService.totalHours(todayEntries);
        const rhythmService = WorkRhythmService();
        final rhythm = rhythmService.calculate(
          entries: entries,
          now: now,
          hourlyRate: settings.hourlyRate,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _DashboardHero(
              monthlyEarnings: currency.format(month.totalEarnings),
              monthlyHours: month.totalHours,
              todayHours: todayHours,
              onQuickAdd: (hours) => _quickAdd(context, ref, settings, hours),
            ),
            const SizedBox(height: 14),
            _EkstraRadarCard(
              projectedMonthlyEarnings: currency.format(
                rhythm.projectedMonthlyEarnings,
              ),
              activeStreakDays: rhythm.activeStreakDays,
              averageHoursPerEntry: rhythm.averageHoursPerEntry,
              busiestDay: rhythm.busiestDay,
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty) ...[
              _EmptyOvertimeState(
                onAddTwoHours: () => _quickAdd(context, ref, settings, 2),
                onOpenToday: () => _openSheet(context, now, entries, settings),
              ),
              const SizedBox(height: 14),
            ],
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.22,
              children: [
                MetricCard(
                  label: 'Bu ay toplam saat',
                  value: '${month.totalHours.toStringAsFixed(1)}s',
                  icon: Icons.timer_rounded,
                  infoTitle: 'Bu ay toplam saat',
                  infoMessage:
                      'Bu ay içinde kaydettiğin tüm mesai kayıtlarının saat toplamıdır.',
                ),
                MetricCard(
                  label: 'Bu ay kazanç',
                  value: currency.format(month.totalEarnings),
                  icon: Icons.payments_rounded,
                  accent: AppColors.green,
                  infoTitle: 'Bu ay kazanç',
                  infoMessage:
                      'Bu ayki tüm kayıtların kazanç toplamıdır. Her kayıt için formül: saat × saatlik ücret × katsayı.',
                ),
                MetricCard(
                  label: 'Bu yıl toplam saat',
                  value: '${yearHours.toStringAsFixed(1)}s',
                  icon: Icons.av_timer_rounded,
                  accent: const Color(0xFF70A1FF),
                  infoTitle: 'Bu yıl toplam saat',
                  infoMessage:
                      'Bu yıl içinde kaydettiğin tüm mesai kayıtlarının saat toplamıdır.',
                ),
                MetricCard(
                  label: 'Bu yıl kazanç',
                  value: currency.format(yearEarnings),
                  icon: Icons.savings_rounded,
                  accent: AppColors.green,
                  infoTitle: 'Bu yıl kazanç',
                  infoMessage:
                      'Bu yılki tüm mesai kayıtlarının tahmini kazanç toplamıdır.',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: TableCalendar<OvertimeEntry>(
                locale: 'tr_TR',
                firstDay: DateTime(now.year - 2),
                lastDay: DateTime(now.year + 2),
                focusedDay: now,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: (day) {
                  return entries
                      .where((entry) => DateKey.isSameDay(entry.date, day))
                      .toList();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(color: AppColors.green),
                  defaultTextStyle: const TextStyle(color: AppColors.white),
                  weekendTextStyle: const TextStyle(color: AppColors.orange),
                  outsideTextStyle: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.35),
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.white,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.white,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final hours = events.fold<double>(
                      0,
                      (sum, entry) => sum + entry.hours,
                    );
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}s',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  _openSheet(context, selectedDay, entries, settings);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EkstraRadarCard extends StatelessWidget {
  const _EkstraRadarCard({
    required this.projectedMonthlyEarnings,
    required this.activeStreakDays,
    required this.averageHoursPerEntry,
    required this.busiestDay,
  });

  final String projectedMonthlyEarnings;
  final int activeStreakDays;
  final double averageHoursPerEntry;
  final OvertimeEntry? busiestDay;

  @override
  Widget build(BuildContext context) {
    final busiestText = busiestDay == null
        ? '-'
        : DateFormat('d MMM', 'tr_TR').format(busiestDay!.date);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ekstra Radar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gelir ritmin ve ay sonu tahmini',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const InfoTooltipButton(
                title: 'Ekstra Radar',
                message:
                    'Bu kart mevcut çalışma ritmine göre ay sonu tahminini, aktif mesai serini, ortalama mesai süreni ve en yoğun gününü gösterir.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navy2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu tempo ile ay sonu',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  projectedMonthlyEarnings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RadarMiniMetric(
                  label: 'Seri',
                  value: '${activeStreakDays}g',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RadarMiniMetric(
                  label: 'Ortalama',
                  value: '${averageHoursPerEntry.toStringAsFixed(1)}s',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF70A1FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RadarMiniMetric(
                  label: 'Yoğun gün',
                  value: busiestText,
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarMiniMetric extends StatelessWidget {
  const _RadarMiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.navy2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.monthlyEarnings,
    required this.monthlyHours,
    required this.todayHours,
    required this.onQuickAdd,
  });

  final String monthlyEarnings;
  final double monthlyHours;
  final double todayHours;
  final ValueChanged<double> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF132640), Color(0xFF0D1B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.16),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.orange,
                ),
              ),
              const Spacer(),
              const InfoTooltipButton(
                title: 'Gerçekleşen kazanç',
                message:
                    'Bu kart bu ay şimdiye kadar kaydettiğin gerçek mesai kazancını gösterir. Formül: her kayıt için saat × saatlik ücret × katsayı.',
              ),
              const SizedBox(width: 8),
              Text(
                'Bugün ${todayHours.toStringAsFixed(1)}s',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Bu ay ekstra kazancın',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            monthlyEarnings,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${monthlyHours.toStringAsFixed(1)} saat mesai kaydedildi',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 3, 4].map((hours) {
              return ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: Text('+${hours}s bugün'),
                backgroundColor: AppColors.orange.withValues(alpha: 0.14),
                side: BorderSide(
                  color: AppColors.orange.withValues(alpha: 0.28),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                onPressed: () => onQuickAdd(hours.toDouble()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyOvertimeState extends StatelessWidget {
  const _EmptyOvertimeState({
    required this.onAddTwoHours,
    required this.onOpenToday,
  });

  final VoidCallback onAddTwoHours;
  final VoidCallback onOpenToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İlk mesaini ekle',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bugünden başla veya takvimden gün seç.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onAddTwoHours,
            icon: const Icon(Icons.add_rounded),
            tooltip: '+2s ekle',
          ),
        ],
      ),
    );
  }
}
