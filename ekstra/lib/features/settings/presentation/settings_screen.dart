import 'package:ekstra/core/config/supabase_config.dart';
import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/services/backup_service.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/auth/presentation/auth_providers.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _DataHealthSummary extends StatelessWidget {
  const _DataHealthSummary({required this.health});

  final OvertimeDataHealth health;

  @override
  Widget build(BuildContext context) {
    final lastBackup = health.latestSnapshotAt == null
        ? '-'
        : DateFormat('d MMM HH:mm', 'tr_TR').format(health.latestSnapshotAt!);
    final lastUpdate = health.latestEntryUpdatedAt == null
        ? '-'
        : DateFormat(
            'd MMM HH:mm',
            'tr_TR',
          ).format(health.latestEntryUpdatedAt!);
    final lastManualBackup = health.latestManualBackupAt == null
        ? 'Henüz yok'
        : DateFormat(
            'd MMM HH:mm',
            'tr_TR',
          ).format(health.latestManualBackupAt!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                health.isHealthy
                    ? Icons.verified_user_rounded
                    : Icons.warning_amber_rounded,
                color: health.isHealthy ? AppColors.green : AppColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  health.isHealthy
                      ? 'Yerel veri durumu sağlıklı'
                      : 'Yerel yedek kontrolü gerekiyor',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HealthRow(label: 'Mesai kaydı', value: '${health.entryCount}'),
          _HealthRow(
            label: 'Otomatik snapshot',
            value: '${health.snapshotCount}',
          ),
          _HealthRow(
            label: 'Arşivlenen işlem',
            value: '${health.archiveCount}',
          ),
          _HealthRow(
            label: 'Denetim kaydı',
            value: '${health.auditEventCount}',
          ),
          _HealthRow(label: 'Son kayıt güncellemesi', value: lastUpdate),
          _HealthRow(label: 'Son otomatik yedek', value: lastBackup),
          _HealthRow(label: 'Son dışa aktarım', value: lastManualBackup),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _AuditTrailPreview extends StatelessWidget {
  const _AuditTrailPreview({required this.events});

  final List<OvertimeAuditEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        'Henüz denetim kaydı yok.',
        style: TextStyle(color: AppColors.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son işlemler',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...events.take(4).map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${event.description} ${DateFormat('d MMM HH:mm', 'tr_TR').format(event.happenedAt)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rate =
        double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    await ref
        .read(settingsControllerProvider.notifier)
        .updateSettings(hourlyRate: rate, hasCompletedOnboarding: true);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mesai verileri silinsin mi?'),
          content: const Text(
            'Bu işlem sadece bu cihazdaki kayıtlı mesaileri temizler.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(overtimeEntriesProvider.notifier).clear();
  }

  Future<void> _exportBackup() async {
    final settings = ref.read(settingsControllerProvider).value;
    final entries = ref.read(overtimeEntriesProvider).value ?? [];
    if (settings == null) return;

    final json = BackupService.exportJson(settings: settings, entries: entries);
    await Clipboard.setData(ClipboardData(text: json));
    await ref
        .read(hiveServiceProvider)
        .integrityBox
        .put(
          AppConstants.latestManualBackupAtKey,
          DateTime.now().toIso8601String(),
        );
    await ref.read(hiveServiceProvider).integrityBox.flush();
    ref.invalidate(overtimeDataHealthProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Yedek panoya kopyalandı.')));
  }

  Future<void> _showImportBackupDialog() async {
    final controller = TextEditingController();
    final backupJson = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yedekten içe aktar'),
          content: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              hintText: 'EKSTRA JSON yedeğini buraya yapıştır',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('İçe aktar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (backupJson == null || backupJson.trim().isEmpty) return;

    try {
      final payload = BackupService.importJson(backupJson);
      await ref
          .read(settingsControllerProvider.notifier)
          .save(payload.settings);
      await ref
          .read(overtimeEntriesProvider.notifier)
          .replaceAll(payload.entries);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yedek içe aktarıldı.')));
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _restoreLatestMesaiBackup() async {
    final restoredCount = await ref
        .read(overtimeEntriesProvider.notifier)
        .restoreLatestBackup();
    if (!mounted) return;
    final message = restoredCount == 0
        ? 'Geri yüklenecek mesai yedeği bulunamadı.'
        : '$restoredCount mesai kaydı son yedekten geri yüklendi.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).value;
    final authSession = ref.watch(authControllerProvider).value;
    final dataHealth = ref.watch(overtimeDataHealthProvider);
    final auditTrail = ref.watch(overtimeAuditTrailProvider);
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rateController.text.isEmpty) {
      _rateController.text = settings.hourlyRate == 0
          ? ''
          : settings.hourlyRate.toString().replaceAll('.0', '');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          'Ayarlar',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ücret bilgisi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Saatlik ücretini buradan değiştirebilirsin.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saatlik ücret',
                  prefixIcon: Icon(Icons.payments_rounded),
                  suffixText: 'TRY',
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateSettings(isDarkMode: value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vardiya sistemi'),
                subtitle: const Text('İlk sürümde maaş hesabını etkilemez.'),
                value: settings.isShiftEnabled,
                onChanged: (value) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateSettings(isShiftEnabled: value);
                },
              ),
              if (settings.isShiftEnabled) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/shifts'),
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Vardiya planını aç'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hesap ve senkronizasyon',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                authSession?.isAuthenticated == true
                    ? 'Bulut hesabı: ${authSession?.email}'
                    : 'Şu an hesapsız kullanıyorsun. Veriler bu cihazda saklanıyor.',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final message = SupabaseConfig.isConfigured
                            ? 'Supabase auth implementasyonu bir sonraki adımda bağlanacak.'
                            : '.env içine Supabase URL ve anon key eklenmeden hesap açma aktif olmaz.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      },
                      icon: const Icon(Icons.cloud_sync_rounded),
                      label: const Text('Hesap bağla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signOut(keepLocalData: true);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Local moda dön',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restoreLatestMesaiBackup,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Son mesai yedeğini geri yükle'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/history'),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('İşlem geçmişi ve silinenler'),
                ),
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
                'Supabase placeholder',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                '.env.example ve repository interface hazır. Gerçek bağlantı MVP dışında.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Mesai verilerini sıfırla'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veri güvenliği',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supabase gelmeden önce kayıtlarını JSON yedeği olarak saklayabilirsin.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              dataHealth.when(
                data: (health) => _DataHealthSummary(health: health),
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (error, _) => Text(
                  'Veri durumu okunamadı: $error',
                  style: const TextStyle(color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 14),
              auditTrail.when(
                data: (events) => _AuditTrailPreview(events: events),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Dışa aktar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showImportBackupDialog,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('İçe aktar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
