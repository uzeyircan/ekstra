import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/dashboard/domain/work_rhythm.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/presentation/overtime_entry_sheet.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:ekstra/features/payroll/domain/salary_estimate.dart';
import 'package:ekstra/features/payroll/domain/salary_estimate_service.dart';
import 'package:ekstra/features/payroll/domain/work_time_balance.dart';
import 'package:ekstra/features/payroll/domain/work_time_balance_service.dart';
import 'package:ekstra/features/payroll/presentation/payroll_providers.dart';
import 'package:ekstra/features/reports/domain/summary_service.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:ekstra/shared/widgets/metric_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _focusedCalendarDay;

  @override
  void initState() {
    super.initState();
    _focusedCalendarDay = DateTime.now();
  }

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
      backgroundColor: Colors.transparent,
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
    final canEdit = await _confirmLockedMonthEdit(context, ref, DateTime.now());
    if (!canEdit) return;
    await ref
        .read(overtimeEntriesProvider.notifier)
        .addQuickHours(
          date: DateTime.now(),
          hours: hours,
          multiplier: settings.defaultMultiplier,
          hourlyRate: settings.hourlyRate,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bugüne +${hours.toStringAsFixed(0)}s eklendi')),
    );
  }

  Future<bool> _confirmLockedMonthEdit(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final lock = await ref.read(
      payrollLockProvider(
        PayrollLock.keyFor(year: date.year, month: date.month),
      ).future,
    );
    if (lock == null) return true;
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bu ay kilitli'),
          content: const Text(
            'Bu ay bordro kapanışıyla kilitlenmiş. Değişiklik kapanmış raporu etkileyebilir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yine de ekle'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
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
        const salaryEstimateService = SalaryEstimateService();
        final salaryEstimate = salaryEstimateService.calculate(
          overtimeEntries: month.entries,
          monthlyNetSalary: settings.monthlyNetSalary,
          hourlyRate: settings.hourlyRate,
          defaultMultiplier: settings.defaultMultiplier,
          monthlyWorkHours: settings.monthlyWorkHours,
        );
        const workTimeBalanceService = WorkTimeBalanceService();
        final workTimeBalance = workTimeBalanceService.calculate(
          expectedMonthlyHours: settings.monthlyWorkHours,
          recordedOvertimeHours: salaryEstimate.totalOvertimeHours,
        );
        final workedDaysThisMonth = month.entries
            .map((entry) => DateKey.fromDate(entry.date))
            .toSet()
            .length;
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
        final dataHealth = ref.watch(overtimeDataHealthProvider);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _DashboardHero(
                  salaryEstimate: salaryEstimate,
                  currency: currency,
                  todayHours: todayHours,
                  onQuickAdd: (hours) =>
                      _quickAdd(context, ref, settings, hours),
                  onLivePressed: () => context.go('/live'),
                )
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.03, end: 0, duration: 260.ms),
            const SizedBox(height: 14),
            _WorkTimeBalanceCard(balance: workTimeBalance)
                .animate(delay: 40.ms)
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.03, end: 0, duration: 260.ms),
            const SizedBox(height: 14),
            _EkstraRadarCard(
                  projectedMonthlyEarnings: currency.format(
                    rhythm.projectedMonthlyEarnings,
                  ),
                  activeStreakDays: rhythm.activeStreakDays,
                  averageHoursPerEntry: rhythm.averageHoursPerEntry,
                  busiestDay: rhythm.busiestDay,
                )
                .animate(delay: 60.ms)
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.03, end: 0, duration: 260.ms),
            if (entries.isEmpty) ...[
              _EmptyOvertimeState(
                onAddTwoHours: () => _quickAdd(context, ref, settings, 2),
                onOpenToday: () => _openSheet(context, now, entries, settings),
              ),
              const SizedBox(height: 14),
            ],
            _SectionHeader(
              title: 'Mesai takvimi',
              subtitle: 'Bu ay $workedDaysThisMonth gün mesai kaydı var',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF12243C), Color(0xFF0B1728)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: TableCalendar<OvertimeEntry>(
                locale: 'tr_TR',
                firstDay: DateTime(now.year - 2),
                lastDay: DateTime(now.year + 2),
                focusedDay: _focusedCalendarDay,
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
                    final color = hours >= 4
                        ? AppColors.green
                        : hours >= 2
                        ? AppColors.orange
                        : const Color(0xFF70A1FF);
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
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
                  setState(() => _focusedCalendarDay = focusedDay);
                  _openSheet(context, selectedDay, entries, settings);
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedCalendarDay = focusedDay);
                },
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(
              title: 'Kazanç özeti',
              subtitle: 'Ay ve yıl bazlı gerçekleşen mesai verileri',
            ),
            const SizedBox(height: 10),
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
            dataHealth.when(
              data: (health) => Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _DataSafetyStrip(health: health),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy2 : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
                      'Ay sonu projeksiyonu',
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
              color: isDark ? AppColors.navy2 : const Color(0xFFF4F8FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ay sonu beklenen',
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

class _WorkTimeBalanceCard extends StatelessWidget {
  const _WorkTimeBalanceCard({required this.balance});

  final WorkTimeBalance balance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (balance.type) {
      WorkTimeBalanceType.over => AppColors.orange,
      WorkTimeBalanceType.under => const Color(0xFF70A1FF),
      WorkTimeBalanceType.balanced => AppColors.green,
      WorkTimeBalanceType.notConfigured => AppColors.muted,
    };
    final icon = switch (balance.type) {
      WorkTimeBalanceType.over => Icons.trending_up_rounded,
      WorkTimeBalanceType.under => Icons.trending_down_rounded,
      WorkTimeBalanceType.balanced => Icons.check_circle_rounded,
      WorkTimeBalanceType.notConfigured => Icons.tune_rounded,
    };
    final title = switch (balance.type) {
      WorkTimeBalanceType.notConfigured => 'Beklenen süreyi ayarla',
      _ => 'Fazla mesai durumu',
    };
    final message = switch (balance.type) {
      WorkTimeBalanceType.over =>
        'Bu ay ${balance.absoluteDifferenceHours.toStringAsFixed(1)} saat fazla çalışmış görünüyorsun.',
      WorkTimeBalanceType.under =>
        'Bu ay beklenen süreden ${balance.absoluteDifferenceHours.toStringAsFixed(1)} saat az çalışmış görünüyorsun.',
      WorkTimeBalanceType.balanced =>
        'Bu ay beklenen çalışma süresine yakın görünüyorsun.',
      WorkTimeBalanceType.notConfigured =>
        'Aylık normal çalışma saatini girersen mesai farkını tahmini olarak takip edebiliriz.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color.withValues(alpha: 0.14), const Color(0xFF0B1728)]
              : [color.withValues(alpha: 0.10), const Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (balance.type != WorkTimeBalanceType.notConfigured) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Beklenen: ${balance.expectedHours.toStringAsFixed(1)}s • Tahmini toplam: ${balance.actualHours.toStringAsFixed(1)}s',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const InfoTooltipButton(
            title: 'Mesai durumu',
            message:
                'Bu kart ayarlardaki aylık normal çalışma saatini baz alır. EKSTRA şu an fazla mesai kaydı tuttuğu için toplam süre, normal süreye kayıtlı fazla mesai saatlerinin eklenmesiyle tahmini gösterilir.',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 96,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy2 : const Color(0xFFF3F7FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
        ),
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
    required this.salaryEstimate,
    required this.currency,
    required this.todayHours,
    required this.onQuickAdd,
    required this.onLivePressed,
  });

  final SalaryEstimate salaryEstimate;
  final NumberFormat currency;
  final double todayHours;
  final ValueChanged<double> onQuickAdd;
  final VoidCallback onLivePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = salaryEstimate.totalOvertimeHours > 0
        ? 'Bu ay ${salaryEstimate.totalOvertimeHours.toStringAsFixed(1)} saat fazla mesai kayıtlı'
        : 'İlk mesaini eklemeye hazır';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF173456), Color(0xFF0A1424)]
              : const [Color(0xFFFFFFFF), Color(0xFFEAF3FC)],
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kazanç Paneli',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const InfoTooltipButton(
                title: 'Maaş tahmini',
                message:
                    'Bu kart ayarlardaki net maaşı veya normal çalışma saati × saatlik ücret hesabını, bu ay kaydettiğin fazla mesai kazancıyla toplar.',
              ),
              const SizedBox(width: 8),
              Text(
                'Bugün ${todayHours.toStringAsFixed(1)}s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              highlight,
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bu ay tahmini kazancın',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(salaryEstimate.estimatedTotalEarnings),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroMiniStat(
                label: 'Normal kazanç',
                value: currency.format(salaryEstimate.normalWorkEarnings),
                icon: Icons.work_rounded,
              ),
              const SizedBox(width: 10),
              _HeroMiniStat(
                label: 'Mesai kazancı',
                value: currency.format(salaryEstimate.overtimeEarnings),
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeroMiniStat(
                label: 'Toplam fazla mesai saati',
                value:
                    '${salaryEstimate.totalOvertimeHours.toStringAsFixed(1)}s',
                icon: Icons.timer_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 3, 4].map((hours) {
              return _QuickAddButton(
                hours: hours,
                onPressed: () => onQuickAdd(hours.toDouble()),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLivePressed,
              icon: const Icon(Icons.play_circle_rounded),
              label: const Text('Canlı mesai ekranı'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.hours, required this.onPressed});

  final int hours;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.23),
                AppColors.orange.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: AppColors.orange, size: 18),
              const SizedBox(width: 6),
              Text(
                '+${hours}s bugün',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataSafetyStrip extends StatelessWidget {
  const _DataSafetyStrip({required this.health});

  final OvertimeDataHealth health;

  @override
  Widget build(BuildContext context) {
    final statusText = health.isHealthy
        ? '${health.entryCount} kayıt güvenle saklanıyor'
        : 'Yedek kontrolü gerekiyor';
    final subtitle = health.latestManualBackupAt == null
        ? 'Dışa aktarım yedeği henüz alınmadı'
        : 'Son dışa aktarım: ${DateFormat('d MMM HH:mm', 'tr_TR').format(health.latestManualBackupAt!)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          InfoTooltipButton(
            title: 'Veri güvenliği',
            message:
                'Bu alan cihazdaki mesai kayıt sayısını, otomatik snapshot durumunu ve son işlem geçmişini özetler. Kayıt ekleme, düzenleme, silme ve geri yükleme işlemleri denetim kaydına yazılır.',
          ),
        ],
      ),
    );
  }
}
