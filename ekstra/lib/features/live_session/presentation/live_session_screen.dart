import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/live_session/domain/live_work_session.dart';
import 'package:ekstra/features/live_session/presentation/live_session_providers.dart';
import 'package:ekstra/features/payroll/domain/payroll_lock.dart';
import 'package:ekstra/features/payroll/presentation/payroll_providers.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/info_tooltip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LiveSessionScreen extends ConsumerWidget {
  const LiveSessionScreen({super.key});

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
            'Bu ay bordro kapanışıyla kilitlenmiş. Canlı mesai kaydı kapanmış raporu etkileyebilir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yine de bitir'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    final session = ref.watch(liveSessionProvider);
    final now = ref.watch(liveTickerProvider).value ?? DateTime.now();

    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'Canlı Mesai',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mesaini başlat, molanı takip et, bitirdiğinde net süre otomatik kayda dönüşsün.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        session.when(
          data: (value) => _LiveSessionSurface(
            session: value,
            now: now,
            settings: settings,
            onFinishRequested: () =>
                _confirmLockedMonthEdit(context, ref, DateTime.now()),
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Canlı mesai okunamadı: $error'),
        ),
      ],
    );
  }
}

class _LiveSessionSurface extends ConsumerWidget {
  const _LiveSessionSurface({
    required this.session,
    required this.now,
    required this.settings,
    required this.onFinishRequested,
  });

  final LiveWorkSession? session;
  final DateTime now;
  final UserSettings settings;
  final Future<bool> Function() onFinishRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = session != null;
    final netSeconds = session?.netSeconds(now) ?? 0;
    final breakSeconds = session?.breakSeconds(now) ?? 0;
    final liveEarning =
        (session?.netHours(now) ?? 0) *
        settings.hourlyRate *
        settings.defaultMultiplier;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TRY ');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? const [Color(0xFF123D31), Color(0xFF0B1728)]
              : const [Color(0xFF182A45), Color(0xFF0B1728)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? AppColors.green.withValues(alpha: 0.34)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.green : AppColors.orange).withValues(
              alpha: 0.14,
            ),
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isActive ? Icons.play_circle_rounded : Icons.timer_rounded,
                  color: AppColors.navy,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Canlı kazanç modu',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'EKSTRA imzalı net mesai takibi',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const InfoTooltipButton(
                title: 'Canlı Mesai',
                message:
                    'Canlı mesai başlatıldığında geçen süre ve mola süresi takip edilir. Bitirdiğinde net süre bugünün mesai kaydına eklenir.',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              _formatDuration(netSeconds),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              currency.format(liveEarning),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _LiveMetric(
                  label: 'Net süre',
                  value: _formatDuration(netSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LiveMetric(
                  label: 'Mola',
                  value: _formatDuration(breakSeconds),
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (isActive) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: session!.isOnBreak
                        ? () => ref.read(liveSessionProvider.notifier).resume()
                        : () => ref
                              .read(liveSessionProvider.notifier)
                              .startBreak(),
                    icon: Icon(
                      session!.isOnBreak
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(session!.isOnBreak ? 'Devam et' : 'Mola'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final canFinish = await onFinishRequested();
                      if (!canFinish) return;
                      final hours = await ref
                          .read(liveSessionProvider.notifier)
                          .finish(settings);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${hours.toStringAsFixed(2)}s canlı mesai kaydedildi.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Bitir'),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(liveSessionProvider.notifier).discard(),
                child: const Text('Vazgeç'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => ref.read(liveSessionProvider.notifier).start(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Canlı mesai başlat'),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.03, end: 0);
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return [
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      secs.toString().padLeft(2, '0'),
    ].join(':');
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.label,
    required this.value,
    this.color = AppColors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.navy2.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
