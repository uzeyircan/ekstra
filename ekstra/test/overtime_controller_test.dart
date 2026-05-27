import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updating an existing entry preserves createdAt', () async {
    final createdAt = DateTime(2026, 5, 1, 9);
    final entry = OvertimeEntry(
      id: '2026-05-24',
      date: DateTime(2026, 5, 24),
      hours: 2,
      note: 'old',
      overtimeType: OvertimeType.normal,
      multiplier: 1.5,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final repository = _FakeOvertimeRepository([entry]);
    final container = ProviderContainer(
      overrides: [overtimeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(overtimeEntriesProvider.future);
    await container
        .read(overtimeEntriesProvider.notifier)
        .upsertDay(
          date: entry.date,
          hours: 3,
          note: 'updated',
          type: OvertimeType.weekend,
          multiplier: 2,
          hourlyRate: 200,
          existingId: entry.id,
        );

    final updated = repository.entries.single;
    expect(updated.createdAt, createdAt);
    expect(updated.updatedAt.isAfter(createdAt), isTrue);
    expect(updated.hours, 3);
    expect(updated.note, 'updated');
    expect(updated.hourlyRateSnapshot, 200);
  });

  test(
    'same-day overwrite preserves createdAt even without explicit id',
    () async {
      final createdAt = DateTime(2026, 5, 1, 9);
      final entry = OvertimeEntry(
        id: '2026-05-24T00:00:00.000',
        date: DateTime(2026, 5, 24),
        hours: 2,
        note: 'old',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final repository = _FakeOvertimeRepository([entry]);
      final container = ProviderContainer(
        overrides: [overtimeRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(overtimeEntriesProvider.future);
      await container
          .read(overtimeEntriesProvider.notifier)
          .upsertDay(
            date: entry.date,
            hours: 4,
            note: 'same day',
            type: OvertimeType.normal,
            multiplier: 1.5,
            hourlyRate: 200,
          );

      final updated = repository.entries.single;
      expect(updated.id, entry.id);
      expect(updated.createdAt, createdAt);
      expect(updated.hours, 4);
    },
  );
}

class _FakeOvertimeRepository implements OvertimeRepository {
  _FakeOvertimeRepository(List<OvertimeEntry> entries) : entries = [...entries];

  final List<OvertimeEntry> entries;

  @override
  Future<void> clear() async => entries.clear();

  @override
  Future<void> delete(String id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<List<OvertimeEntry>> getAll() async => [...entries];

  @override
  Future<List<OvertimeAuditEvent>> getAuditTrail({int limit = 20}) async => [];

  @override
  Future<List<ArchivedOvertimeEntry>> getDeletedEntries({
    int limit = 30,
  }) async => [];

  @override
  Future<OvertimeDataHealth> getDataHealth() async {
    return OvertimeDataHealth(
      entryCount: entries.length,
      snapshotCount: 0,
      archiveCount: 0,
      auditEventCount: 0,
      hasRestorableBackup: false,
    );
  }

  @override
  Future<int> restoreLatestBackup() async => 0;

  @override
  Future<void> restoreDeletedEntry(String archiveKey) async {}

  @override
  Future<void> upsert(OvertimeEntry entry) async {
    entries.removeWhere((item) => item.id == entry.id);
    entries.add(entry);
  }
}
