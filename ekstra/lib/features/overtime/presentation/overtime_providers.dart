import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/overtime/data/local_overtime_repository.dart';
import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overtimeRepositoryProvider = Provider<OvertimeRepository>((ref) {
  return LocalOvertimeRepository(ref.watch(hiveServiceProvider));
});

final overtimeEntriesProvider =
    AsyncNotifierProvider<OvertimeEntriesController, List<OvertimeEntry>>(
      OvertimeEntriesController.new,
    );

final overtimeDataHealthProvider = FutureProvider<OvertimeDataHealth>((ref) {
  return ref.watch(overtimeRepositoryProvider).getDataHealth();
});

final overtimeAuditTrailProvider = FutureProvider<List<OvertimeAuditEvent>>((
  ref,
) {
  return ref.watch(overtimeRepositoryProvider).getAuditTrail(limit: 50);
});

final deletedOvertimeEntriesProvider =
    FutureProvider<List<ArchivedOvertimeEntry>>((ref) {
      return ref.watch(overtimeRepositoryProvider).getDeletedEntries(limit: 50);
    });

class OvertimeEntriesController extends AsyncNotifier<List<OvertimeEntry>> {
  OvertimeRepository get _repository => ref.read(overtimeRepositoryProvider);

  @override
  Future<List<OvertimeEntry>> build() => _repository.getAll();

  Future<void> upsertDay({
    required DateTime date,
    required double hours,
    required String note,
    required OvertimeType type,
    required double multiplier,
    required double hourlyRate,
    String workplaceNote = '',
    String referenceCode = '',
    bool isPayrollChecked = false,
    String? existingId,
  }) async {
    final now = DateTime.now();
    final entryId = existingId ?? DateKey.fromDate(date);
    final entries = state.value ?? await _repository.getAll();
    final existing = entries.where((entry) => entry.id == entryId).firstOrNull;
    final entry = OvertimeEntry(
      id: entryId,
      date: DateKey.onlyDate(date),
      hours: hours,
      note: note,
      overtimeType: type,
      multiplier: multiplier,
      hourlyRateSnapshot: hourlyRate,
      workplaceNote: workplaceNote,
      referenceCode: referenceCode,
      isPayrollChecked: isPayrollChecked,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsert(entry);
    state = AsyncData(await _repository.getAll());
    _invalidateSafetyProviders();
  }

  Future<void> addQuickHours({
    required DateTime date,
    required double hours,
    required double multiplier,
    required double hourlyRate,
  }) async {
    final entries = state.value ?? await _repository.getAll();
    final existing = entries
        .where((entry) => DateKey.isSameDay(entry.date, date))
        .firstOrNull;

    await upsertDay(
      date: date,
      hours: (existing?.hours ?? 0) + hours,
      note: existing?.note ?? '',
      type: existing?.overtimeType ?? OvertimeType.normal,
      multiplier: existing?.multiplier ?? multiplier,
      hourlyRate: existing?.hourlyRateSnapshot ?? hourlyRate,
      workplaceNote: existing?.workplaceNote ?? '',
      referenceCode: existing?.referenceCode ?? '',
      isPayrollChecked: existing?.isPayrollChecked ?? false,
      existingId: existing?.id,
    );
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = AsyncData(await _repository.getAll());
    _invalidateSafetyProviders();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const AsyncData([]);
    _invalidateSafetyProviders();
  }

  Future<void> replaceAll(List<OvertimeEntry> entries) async {
    await _repository.clear();
    for (final entry in entries) {
      await _repository.upsert(entry);
    }
    state = AsyncData(await _repository.getAll());
    _invalidateSafetyProviders();
  }

  Future<int> restoreLatestBackup() async {
    final restoredCount = await _repository.restoreLatestBackup();
    state = AsyncData(await _repository.getAll());
    _invalidateSafetyProviders();
    return restoredCount;
  }

  Future<void> restoreDeletedEntry(String archiveKey) async {
    await _repository.restoreDeletedEntry(archiveKey);
    state = AsyncData(await _repository.getAll());
    _invalidateSafetyProviders();
  }

  void _invalidateSafetyProviders() {
    ref.invalidate(overtimeDataHealthProvider);
    ref.invalidate(overtimeAuditTrailProvider);
    ref.invalidate(deletedOvertimeEntriesProvider);
  }
}
