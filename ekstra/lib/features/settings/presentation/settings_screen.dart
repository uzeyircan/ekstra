import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/services/backup_service.dart';
import 'package:ekstra/core/theme/app_theme.dart';
import 'package:ekstra/features/auth/presentation/auth_providers.dart';
import 'package:ekstra/features/day_status/presentation/day_status_providers.dart';
import 'package:ekstra/features/monetization/domain/purchase_result.dart';
import 'package:ekstra/features/monetization/presentation/entitlement_providers.dart';
import 'package:ekstra/features/notifications/presentation/notification_providers.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/shifts/presentation/shift_providers.dart';
import 'package:ekstra/features/sync/presentation/cloud_sync_providers.dart';
import 'package:ekstra/shared/widgets/instant_date_picker.dart';
import 'package:ekstra/shared/widgets/premium_panel.dart';
import 'package:flutter/foundation.dart';
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
    final lastIntegrityCheck = health.latestIntegrityCheckAt == null
        ? '-'
        : DateFormat(
            'd MMM HH:mm',
            'tr_TR',
          ).format(health.latestIntegrityCheckAt!);

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
                      : 'Yerel veri kontrolü uyarı verdi',
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
          _HealthRow(label: 'Bütünlük kontrolü', value: lastIntegrityCheck),
          _HealthRow(
            label: 'Kayıt parmak izi',
            value: health.isIntegrityVerified ? 'Doğrulandı' : 'Uyarı',
          ),
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
  final _salaryController = TextEditingController();
  final _workHoursController = TextEditingController();

  @override
  void dispose() {
    _rateController.dispose();
    _salaryController.dispose();
    _workHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rate =
        double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    final monthlySalary =
        double.tryParse(_salaryController.text.replaceAll(',', '.')) ?? 0;
    final monthlyWorkHours =
        double.tryParse(_workHoursController.text.replaceAll(',', '.')) ?? 0;
    await ref
        .read(settingsControllerProvider.notifier)
        .updateSettings(
          hourlyRate: rate,
          monthlyNetSalary: monthlySalary,
          monthlyWorkHours: monthlyWorkHours,
          hasCompletedOnboarding: true,
        );
  }

  Future<void> _pickSalaryDay(int currentDay) async {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final initialDate = DateTime(
      now.year,
      now.month,
      currentDay.clamp(1, lastDay),
    );
    final selected = await showInstantDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month),
      lastDate: DateTime(now.year, now.month, lastDay),
      title: 'Maaş gününü seç',
    );
    if (selected == null) return;
    await ref
        .read(settingsControllerProvider.notifier)
        .updateSettings(salaryDayOfMonth: selected.day);
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

  Future<void> _uploadCloudBackup() async {
    try {
      final result = await ref
          .read(cloudSyncControllerProvider.notifier)
          .upload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _restoreCloudBackup() async {
    try {
      final result = await ref
          .read(cloudSyncControllerProvider.notifier)
          .restoreMissing();
      ref.invalidate(overtimeEntriesProvider);
      ref.invalidate(overtimeDataHealthProvider);
      ref.invalidate(shiftsProvider);
      ref.invalidate(shiftTemplatesProvider);
      ref.invalidate(shiftAssignmentsProvider);
      ref.invalidate(dayStatusesProvider);
      ref.invalidate(settingsControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _restorePurchases() async {
    final result = await ref.read(purchaseServiceProvider).restorePurchases();
    if (!mounted) return;
    final message = switch (result.status) {
      PurchaseResultStatus.started => 'Satın alma işlemi başlatıldı.',
      PurchaseResultStatus.restored =>
        'Satın alımlar geri yükleniyor. Pro satın alman varsa otomatik aktifleşir.',
      PurchaseResultStatus.storeUnavailable => 'Mağaza şu an kullanılamıyor.',
      PurchaseResultStatus.productUnavailable =>
        'Pro ürünü mağazada bulunamadı.',
      PurchaseResultStatus.failed => 'Geri yükleme başlatılamadı.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).value;
    final authSession = ref.watch(authControllerProvider).value;
    final entitlement = ref.watch(entitlementControllerProvider).value;
    final dataHealth = ref.watch(overtimeDataHealthProvider);
    final auditTrail = ref.watch(overtimeAuditTrailProvider);
    final cloudSyncState = ref.watch(cloudSyncControllerProvider);
    final latestCloudSyncAt = ref.watch(latestCloudSyncAtProvider);
    final isCloudSyncing = cloudSyncState.isLoading;
    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rateController.text.isEmpty) {
      _rateController.text = settings.hourlyRate == 0
          ? ''
          : settings.hourlyRate.toString().replaceAll('.0', '');
    }
    if (_salaryController.text.isEmpty) {
      _salaryController.text = settings.monthlyNetSalary == 0
          ? ''
          : settings.monthlyNetSalary.toString().replaceAll('.0', '');
    }
    if (_workHoursController.text.isEmpty) {
      _workHoursController.text = settings.monthlyWorkHours == 0
          ? ''
          : settings.monthlyWorkHours.toString().replaceAll('.0', '');
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ekstra Pro',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entitlement?.isPro == true
                              ? 'Pro durumu: Pro'
                              : 'Pro durumu: Free',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/pro'),
                    child: const Text('İncele'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (kDebugMode)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Debug Pro modu'),
                  subtitle: const Text(
                    'Gerçek satın alma bağlanana kadar test amaçlıdır.',
                  ),
                  value: entitlement?.isPro ?? false,
                  onChanged: (value) {
                    ref
                        .read(entitlementControllerProvider.notifier)
                        .setMockPro(value);
                  },
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restorePurchases,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Satın alımları geri yükle'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gizlilik politikası URL’i eklenecek.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Gizlilik politikası'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanım şartları URL’i eklenecek.'),
                          ),
                        );
                      },
                      child: const Text('Kullanım şartları'),
                    ),
                  ),
                ],
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
                'Maaş tahmini',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Net maaş, saatlik ücret ve normal çalışma saatini tahmini toplam kazanç için kullanırız.',
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
              const SizedBox(height: 12),
              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık net maaş',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  suffixText: 'TRY',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _workHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aylık normal çalışma saati',
                  prefixIcon: Icon(Icons.work_history_rounded),
                  suffixText: 's',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickSalaryDay(settings.salaryDayOfMonth),
                borderRadius: BorderRadius.circular(18),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Maaş günü',
                    prefixIcon: Icon(Icons.event_available_rounded),
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(
                    'Her ayın ${settings.salaryDayOfMonth}. günü',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1x')),
                  ButtonSegment(value: 1.5, label: Text('1.5x')),
                  ButtonSegment(value: 2, label: Text('2x')),
                ],
                selected: {settings.defaultMultiplier},
                onSelectionChanged: (values) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateSettings(defaultMultiplier: values.first);
                },
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
                'Bildirimler',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rahatsız etmeyen vardiya, maaş günü ve ay sonu hatırlatmaları.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bildirimleri aç'),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .updateSettings(notificationsEnabled: value);
                  await ref.read(notificationSyncControllerProvider).sync();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vardiyadan 30 dakika önce'),
                value: settings.shiftReminderEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .updateSettings(shiftReminderEnabled: value);
                        await ref
                            .read(notificationSyncControllerProvider)
                            .sync();
                      }
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vardiya bitince mesai hatırlat'),
                value: settings.overtimeReminderEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .updateSettings(overtimeReminderEnabled: value);
                        await ref
                            .read(notificationSyncControllerProvider)
                            .sync();
                      }
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maaş günü hatırlatması'),
                value: settings.salaryReminderEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .updateSettings(salaryReminderEnabled: value);
                        await ref
                            .read(notificationSyncControllerProvider)
                            .sync();
                      }
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ay sonu mesai özeti'),
                value: settings.monthlySummaryReminderEnabled,
                onChanged: settings.notificationsEnabled
                    ? (value) async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .updateSettings(
                              monthlySummaryReminderEnabled: value,
                            );
                        await ref
                            .read(notificationSyncControllerProvider)
                            .sync();
                      }
                    : null,
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
                'Yerel profil ve yedekleme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'EKSTRA verilerini bu cihazda saklar. Hesapli veya hesapsiz kullansan da mevcut mesai kayitlarin silinmez.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      authSession?.isAuthenticated == true
                          ? Icons.verified_user_rounded
                          : Icons.person_outline_rounded,
                      color: authSession?.isAuthenticated == true
                          ? AppColors.green
                          : AppColors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authSession?.isAuthenticated == true
                                ? authSession!.email
                                : 'Hesapsiz kullanim',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Veriler bu cihazda korunur',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: authSession?.isAuthenticated == true
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut(keepLocalData: true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hesaptan cikildi. Mesai verilerin silinmedi.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Hesaptan cik'),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => context.go('/auth'),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Hesap olustur veya giris yap'),
                      ),
              ),
              if (authSession?.isAuthenticated == true) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isCloudSyncing ? null : _uploadCloudBackup,
                        icon: isCloudSyncing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Buluta yedekle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isCloudSyncing ? null : _restoreCloudBackup,
                        icon: const Icon(Icons.cloud_download_rounded),
                        label: const Text('Eksikleri getir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  latestCloudSyncAt == null
                      ? 'Bulut yedegi henuz alinmadi.'
                      : 'Son bulut islemi: ${DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(latestCloudSyncAt)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                'Yerel veri yonetimi',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tum kayitlar bu cihazda saklanir. Sifirlama islemi yalnizca mesai verilerini temizler.',
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
                'Kayitlarini JSON yedegi olarak saklayabilir ve gerektiginde geri yukleyebilirsin.',
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
