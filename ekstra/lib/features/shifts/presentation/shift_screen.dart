import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';
import 'package:ekstra/features/shifts/presentation/shift_providers.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(shiftsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'Vardiya planı',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'İlk sürümde vardiya bilgisi maaş hesabını etkilemez; kayıtları sınıflandırmak için hazır altyapıdır.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        shifts.when(
          data: (items) => Column(
            children: items
                .map(
                  (shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShiftTile(shift: shift),
                  ),
                )
                .toList(),
          ),
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (error, _) => Text('Vardiyalar okunamadı: $error'),
        ),
      ],
    );
  }
}

class _ShiftTile extends ConsumerWidget {
  const _ShiftTile({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(shift.color);

    return PremiumPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.schedule_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: shift.isEnabled,
            onChanged: (value) {
              ref.read(shiftsProvider.notifier).toggle(shift, value);
            },
          ),
        ],
      ),
    );
  }
}
