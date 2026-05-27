import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OvertimeHistoryScreen extends ConsumerWidget {
  const OvertimeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditTrail = ref.watch(overtimeAuditTrailProvider);
    final deletedEntries = ref.watch(deletedOvertimeEntriesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'İşlem geçmişi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mesai ekleme, düzenleme, silme ve geri yükleme kayıtları.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silinen kayıtlar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              deletedEntries.when(
                data: (items) => _DeletedEntriesList(items: items),
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Text('Okunamadı: $error'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Denetim kaydı',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              auditTrail.when(
                data: (events) => _AuditList(events: events),
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Text('Okunamadı: $error'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeletedEntriesList extends ConsumerWidget {
  const _DeletedEntriesList({required this.items});

  final List<ArchivedOvertimeEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Text(
        'Geri alınabilecek silinmiş kayıt yok.',
        style: TextStyle(color: AppColors.muted),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.restore_rounded, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'd MMMM yyyy',
                        'tr_TR',
                      ).format(item.entry.date),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.entry.hours.toStringAsFixed(1)}s • ${DateFormat('d MMM HH:mm', 'tr_TR').format(item.archivedAt)} silindi',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(overtimeEntriesProvider.notifier)
                      .restoreDeletedEntry(item.archiveKey);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silinen kayıt geri alındı.')),
                  );
                },
                child: const Text('Geri al'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.events});

  final List<OvertimeAuditEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        'Henüz işlem kaydı yok.',
        style: TextStyle(color: AppColors.muted),
      );
    }

    return Column(
      children: events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history_rounded, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.description,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat(
                        'd MMMM yyyy HH:mm',
                        'tr_TR',
                      ).format(event.happenedAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
