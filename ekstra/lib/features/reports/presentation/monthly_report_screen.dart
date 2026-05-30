import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/monetization/domain/monetized_feature.dart';
import 'package:ekstra/features/monetization/presentation/monetization_gate.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/payroll/domain/payroll_check.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:ekstra/features/payroll/presentation/payroll_providers.dart';
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

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(overtimeEntriesProvider).value ?? [];
    final settings = ref.watch(settingsControllerProvider).value;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');
    final hourlyRate = settings?.hourlyRate ?? 0;
    final payrollKey = PayrollCheck.keyFor(
      year: _focusedMonth.year,
      month: _focusedMonth.month,
    );
    final payrollCheck = ref.watch(payrollCheckProvider(payrollKey));
    final payrollLock = ref.watch(payrollLockProvider(payrollKey));
    const service = SummaryService();
    const fileExportService = ReportFileExportService();
    final summary = service.monthly(
      entries: entries,
      year: _focusedMonth.year,
      month: _focusedMonth.month,
      hourlyRate: hourlyRate,
    );
    final dailyHours = service.monthlyHoursByDay(
      entries: entries,
      year: _focusedMonth.year,
      month: _focusedMonth.month,
    );
    final workedDayCount = summary.entries
        .map(
          (entry) =>
              DateTime(entry.date.year, entry.date.month, entry.date.day),
        )
        .toSet()
        .length;
    final averageHours = workedDayCount == 0
        ? 0.0
        : summary.totalHours / workedDayCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _MonthlyHero(
          title: DateFormat('MMMM yyyy', 'tr_TR').format(_focusedMonth),
          earnings: currency.format(summary.totalEarnings),
          totalHours: summary.totalHours,
          workedDayCount: workedDayCount,
          averageHours: averageHours,
          onPreviousMonth: _goToPreviousMonth,
          onNextMonth: _goToNextMonth,
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
        payrollCheck.when(
          data: (check) => _PayrollCheckPanel(
            check: check,
            expectedHours: summary.totalHours,
            expectedEarnings: summary.totalEarnings,
            currency: currency,
            onSave: (hours, earnings, note) async {
              final next = PayrollCheck(
                year: _focusedMonth.year,
                month: _focusedMonth.month,
                payrollHours: hours,
                payrollEarnings: earnings,
                note: note,
                updatedAt: DateTime.now(),
              );
              await ref.read(payrollRepositoryProvider).save(next);
              ref.invalidate(payrollCheckProvider(payrollKey));
            },
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Bordro kontrolü okunamadı: $error'),
        ),
        const SizedBox(height: 16),
        payrollLock.when(
          data: (lock) => _PayrollLockPanel(
            lock: lock,
            year: _focusedMonth.year,
            month: _focusedMonth.month,
            onChanged: () => ref.invalidate(payrollLockProvider(payrollKey)),
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Ay kilidi okunamadı: $error'),
        ),
        const SizedBox(height: 16),
        ExportActionPanel(
          title: 'Dosya olarak al',
          subtitle:
              'Bordro kontrolü için aylık raporu PDF veya CSV olarak paylaş.',
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                final canContinue = await requireRewardedAdOrPro(
                  context: context,
                  ref: ref,
                  feature: MonetizedFeature.pdfExport,
                  title: 'Ay sonu raporu',
                  message: 'Aylık rapor çıktısını oluşturmak üzeresin.',
                );
                if (!canContinue || !context.mounted) return;
                await fileExportService.shareMonthlyPdf(
                  summary: summary,
                  hourlyRate: hourlyRate,
                  formattedTotalEarnings: currency.format(
                    summary.totalEarnings,
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aylık PDF raporu hazırlandı.')),
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
                  title: 'Aylık CSV raporu',
                  message:
                      'Excel ile açılabilen aylık CSV çıktısı oluşturulacak.',
                );
                if (!canContinue || !context.mounted) return;
                await fileExportService.shareMonthlyCsv(
                  summary: summary,
                  hourlyRate: hourlyRate,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aylık CSV raporu hazırlandı.')),
                );
              },
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('CSV'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (summary.entries.isEmpty) ...[
          const _ReportEmptyState(
            title: 'Bu ay henüz mesai yok',
            message:
                'Takvimden gün seçip ilk mesaini eklediğinde burada görünür.',
          ),
        ] else
          ...summary.entries.map(
            (entry) => _EntrySummaryTile(
              title: DateFormat('d MMMM EEEE', 'tr_TR').format(entry.date),
              subtitle: entry.overtimeType.label,
              hours: '${entry.hours.toStringAsFixed(1)}s',
              earning: currency.format(entry.earning(hourlyRate)),
            ),
          ),
      ],
    );
  }
}

class _MonthlyHero extends StatelessWidget {
  const _MonthlyHero({
    required this.title,
    required this.earnings,
    required this.totalHours,
    required this.workedDayCount,
    required this.averageHours,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String title;
  final String earnings;
  final double totalHours;
  final int workedDayCount;
  final double averageHours;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

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
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Önceki ay',
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Sonraki ay',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Aylık tahmini ekstra gelir',
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
              _HeroPill(
                label: 'Toplam',
                value: '${totalHours.toStringAsFixed(1)}s',
              ),
              const SizedBox(width: 8),
              _HeroPill(label: 'Gün', value: '$workedDayCount'),
              const SizedBox(width: 8),
              _HeroPill(
                label: 'Ort.',
                value: '${averageHours.toStringAsFixed(1)}s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value});

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

class _EntrySummaryTile extends StatelessWidget {
  const _EntrySummaryTile({
    required this.title,
    required this.subtitle,
    required this.hours,
    required this.earning,
  });

  final String title;
  final String subtitle;
  final String hours;
  final String earning;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.surface2,
            child: Icon(Icons.bolt_rounded, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hours, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(earning, style: const TextStyle(color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayrollCheckPanel extends StatelessWidget {
  const _PayrollCheckPanel({
    required this.check,
    required this.expectedHours,
    required this.expectedEarnings,
    required this.currency,
    required this.onSave,
  });

  final PayrollCheck? check;
  final double expectedHours;
  final double expectedEarnings;
  final NumberFormat currency;
  final Future<void> Function(double hours, double earnings, String note)
  onSave;

  @override
  Widget build(BuildContext context) {
    final hourDiff = check == null ? null : check!.payrollHours - expectedHours;
    final earningDiff = check == null
        ? null
        : check!.payrollEarnings - expectedEarnings;

    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bordro kontrolü',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openDialog(context),
                child: Text(check == null ? 'Gir' : 'Düzenle'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (check == null)
            const Text(
              'Bordroda görünen saat ve kazancı girerek farkı kontrol edebilirsin.',
              style: TextStyle(color: AppColors.muted),
            )
          else ...[
            _DiffRow(
              label: 'Saat farkı',
              value: '${hourDiff!.toStringAsFixed(1)}s',
              isPositive: hourDiff >= 0,
            ),
            _DiffRow(
              label: 'Kazanç farkı',
              value: currency.format(earningDiff),
              isPositive: earningDiff! >= 0,
            ),
            if (check!.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                check!.note,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final hoursController = TextEditingController(
      text: check?.payrollHours.toString().replaceAll('.0', '') ?? '',
    );
    final earningsController = TextEditingController(
      text: check?.payrollEarnings.toString().replaceAll('.0', '') ?? '',
    );
    final noteController = TextEditingController(text: check?.note ?? '');
    final result =
        await showDialog<({double hours, double earnings, String note})>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Bordro değerleri'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bordro saati',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: earningsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bordro kazancı',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'İtiraz notu'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop((
                      hours:
                          double.tryParse(
                            hoursController.text.replaceAll(',', '.'),
                          ) ??
                          0,
                      earnings:
                          double.tryParse(
                            earningsController.text.replaceAll(',', '.'),
                          ) ??
                          0,
                      note: noteController.text.trim(),
                    ));
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
    hoursController.dispose();
    earningsController.dispose();
    noteController.dispose();
    if (result == null) return;
    await onSave(result.hours, result.earnings, result.note);
  }
}

class _PayrollLockPanel extends ConsumerWidget {
  const _PayrollLockPanel({
    required this.lock,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  final PayrollLock? lock;
  final int year;
  final int month;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = lock != null;
    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: isLocked ? AppColors.green : AppColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLocked ? 'Bordro kapandı' : 'Ay kilidi açık',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    isLocked ? _unlock(context, ref) : _lock(context, ref),
                child: Text(isLocked ? 'Kilidi aç' : 'Ayı kilitle'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLocked
                ? 'Bu ay ${DateFormat('d MMM HH:mm', 'tr_TR').format(lock!.lockedAt)} tarihinde kapatıldı. Mesai ekleme/düzenleme sırasında uyarı gösterilir.'
                : 'Bordroyu kontrol ettikten sonra ayı kilitleyerek yanlışlıkla değişiklik yapılmasını önleyebilirsin.',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (lock?.note.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              lock!.note,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _lock(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ay kilitlensin mi?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Kapanış notu',
              hintText: 'Örn: Bordro kontrol edildi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Kilitle'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (note == null) return;
    await ref
        .read(payrollLockRepositoryProvider)
        .save(
          PayrollLock(
            year: year,
            month: month,
            lockedAt: DateTime.now(),
            note: note.trim(),
          ),
        );
    onChanged();
  }

  Future<void> _unlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kilit açılsın mı?'),
          content: const Text(
            'Bu ay tekrar düzenlenebilir hale gelir. Mevcut kayıtlar silinmez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kilidi aç'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref
        .read(payrollLockRepositoryProvider)
        .unlock(year: year, month: month);
    onChanged();
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  final String label;
  final String value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? AppColors.green : AppColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  const _ReportEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Row(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
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
                            gradient: hasValue
                                ? const LinearGradient(
                                    colors: [AppColors.orange, AppColors.green],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                            color: hasValue ? null : AppColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: hasValue
                                ? [
                                    BoxShadow(
                                      color: AppColors.orange.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
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
