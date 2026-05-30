import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/services/integrity_hash_service.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';

class LocalOvertimeRepository implements OvertimeRepository {
  const LocalOvertimeRepository(this._hive);

  final HiveService _hive;

  @override
  Future<List<OvertimeEntry>> getAll() async {
    final entries = _readPrimaryEntries();
    if (entries.isNotEmpty || _hive.entrySnapshotsBox.isEmpty) {
      return entries..sort((a, b) => b.date.compareTo(a.date));
    }

    final restored = await _restoreLatestNonEmptySnapshot();
    return restored..sort((a, b) => b.date.compareTo(a.date));
  }

  List<OvertimeEntry> _readPrimaryEntries() {
    return _hive.entriesBox.values
        .map(_tryParseEntry)
        .whereType<OvertimeEntry>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> upsert(OvertimeEntry entry) async {
    final existing = _hive.entriesBox.get(entry.id);
    final before = _mapOrNull(existing);
    if (existing != null) {
      await _archiveEntry(id: entry.id, value: existing, reason: 'upsert');
    }
    await _hive.entriesBox.put(entry.id, entry.toJson());
    await _hive.entriesBox.flush();
    await _writeAuditEvent(
      action: existing == null ? 'create' : 'update',
      entryId: entry.id,
      description: existing == null
          ? 'Mesai kaydı oluşturuldu.'
          : 'Mesai kaydı güncellendi.',
      before: before,
      after: entry.toJson(),
    );
    await _writeSnapshot(reason: 'upsert');
  }

  @override
  Future<void> delete(String id) async {
    final existing = _hive.entriesBox.get(id);
    if (existing != null) {
      await _archiveEntry(id: id, value: existing, reason: 'delete');
    }
    await _hive.entriesBox.delete(id);
    await _hive.entriesBox.flush();
    await _writeAuditEvent(
      action: 'delete',
      entryId: id,
      description: 'Mesai kaydı silindi.',
      before: _mapOrNull(existing),
    );
    await _writeSnapshot(reason: 'delete');
  }

  @override
  Future<void> clear() async {
    await _writeSnapshot(reason: 'before_clear');
    await _writeAuditEvent(
      action: 'clear',
      entryId: '*',
      description: '${_hive.entriesBox.length} mesai kaydı temizlendi.',
    );
    await _hive.entriesBox.clear();
    await _hive.entriesBox.flush();
    await _writeSnapshot(reason: 'clear');
  }

  @override
  Future<int> restoreLatestBackup() async {
    final entries = await _restoreLatestNonEmptySnapshot(
      allowOlderSnapshots: true,
    );
    return entries.length;
  }

  @override
  Future<OvertimeDataHealth> getDataHealth() async {
    var entries = _readPrimaryEntries();
    if (entries.isNotEmpty &&
        _latestSnapshot(allowOlderSnapshots: true) == null) {
      await _writeSnapshot(reason: 'bootstrap_health_snapshot');
      entries = _readPrimaryEntries();
    }
    final snapshots = _hive.entrySnapshotsBox.values.whereType<Map>();
    final latestSnapshotAt = snapshots
        .map((snapshot) => _tryParseDate(snapshot['createdAt']))
        .whereType<DateTime>()
        .fold<DateTime?>(null, _latestDate);
    final latestAuditAt = (await getAuditTrail(
      limit: 1,
    )).firstOrNull?.happenedAt;
    final latestEntryUpdatedAt = entries
        .map((entry) => entry.updatedAt)
        .fold<DateTime?>(null, _latestDate);
    final latestManualBackupAt = _tryParseDate(
      _hive.integrityBox.get(AppConstants.latestManualBackupAtKey),
    );
    final latestIntegrityCheckAt = DateTime.now();
    final isIntegrityVerified = _verifyEntriesDigest(entries);
    await _hive.integrityBox.put(
      AppConstants.latestIntegrityCheckAtKey,
      latestIntegrityCheckAt.toIso8601String(),
    );
    await _hive.integrityBox.flush();

    return OvertimeDataHealth(
      entryCount: _hive.entriesBox.length,
      snapshotCount: _hive.entrySnapshotsBox.length,
      archiveCount: _hive.entryArchiveBox.length,
      auditEventCount: _hive.entryAuditBox.length,
      hasRestorableBackup: _latestSnapshot(allowOlderSnapshots: true) != null,
      isIntegrityVerified: isIntegrityVerified,
      latestEntryUpdatedAt: latestEntryUpdatedAt,
      latestSnapshotAt: latestSnapshotAt,
      latestAuditAt: latestAuditAt,
      latestManualBackupAt: latestManualBackupAt,
      latestIntegrityCheckAt: latestIntegrityCheckAt,
    );
  }

  @override
  Future<List<OvertimeAuditEvent>> getAuditTrail({int limit = 20}) async {
    final events =
        _hive.entryAuditBox.values
            .map(_tryParseAuditEvent)
            .whereType<OvertimeAuditEvent>()
            .toList()
          ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return events.take(limit).toList();
  }

  @override
  Future<List<ArchivedOvertimeEntry>> getDeletedEntries({
    int limit = 30,
  }) async {
    final archived = <ArchivedOvertimeEntry>[];
    for (final key in _hive.entryArchiveBox.keys) {
      final value = _hive.entryArchiveBox.get(key);
      final item = _tryParseArchiveItem(key.toString(), value);
      if (item != null && item.reason == 'delete') {
        archived.add(item);
      }
    }
    archived.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
    return archived.take(limit).toList();
  }

  @override
  Future<void> restoreDeletedEntry(String archiveKey) async {
    final value = _hive.entryArchiveBox.get(archiveKey);
    final item = _tryParseArchiveItem(archiveKey, value);
    if (item == null) return;

    await _hive.entriesBox.put(item.entry.id, item.entry.toJson());
    await _hive.entriesBox.flush();
    await _writeAuditEvent(
      action: 'restore_deleted',
      entryId: item.entry.id,
      description: 'Silinen mesai kaydı geri alındı.',
      after: item.entry.toJson(),
    );
    await _writeSnapshot(reason: 'restore_deleted');
  }

  OvertimeEntry? _tryParseEntry(dynamic value) {
    try {
      return OvertimeEntry.fromJson(value as Map<dynamic, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> _archiveEntry({
    required String id,
    required dynamic value,
    required String reason,
  }) async {
    final key = '${DateTime.now().microsecondsSinceEpoch}_$id';
    await _hive.entryArchiveBox.put(key, {
      'id': id,
      'reason': reason,
      'archivedAt': DateTime.now().toIso8601String(),
      'entry': value,
    });
    await _hive.entryArchiveBox.flush();
  }

  Future<void> _writeAuditEvent({
    required String action,
    required String entryId,
    required String description,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    final now = DateTime.now();
    final key = '${now.microsecondsSinceEpoch}_$action';
    final event = OvertimeAuditEvent(
      id: key,
      action: action,
      entryId: entryId,
      happenedAt: now,
      description: description,
      before: before,
      after: after,
    );
    await _hive.entryAuditBox.put(key, event.toJson());
    await _hive.entryAuditBox.flush();
    await _pruneAuditTrail();
  }

  Future<void> _pruneAuditTrail() async {
    const maxAuditEvents = 200;
    final keys = _hive.entryAuditBox.keys.cast<String>().toList()..sort();
    if (keys.length <= maxAuditEvents) return;
    final staleKeys = keys.take(keys.length - maxAuditEvents);
    for (final key in staleKeys) {
      await _hive.entryAuditBox.delete(key);
    }
    await _hive.entryAuditBox.flush();
  }

  Future<void> _writeSnapshot({required String reason}) async {
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    final entries = _readPrimaryEntries();
    final digest = _entriesDigest(entries);
    final snapshot = {
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
      'digest': digest,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
    await _hive.entrySnapshotsBox.put(key, snapshot);
    await _hive.integrityBox.put(AppConstants.latestEntrySnapshotKey, key);
    await _hive.integrityBox.put(AppConstants.latestEntryDigestKey, digest);
    await Future.wait([
      _hive.entrySnapshotsBox.flush(),
      _hive.integrityBox.flush(),
    ]);
    await _pruneSnapshots();
  }

  Future<void> _pruneSnapshots() async {
    const maxSnapshots = 40;
    final keys = _hive.entrySnapshotsBox.keys.cast<String>().toList()..sort();
    if (keys.length <= maxSnapshots) return;
    final staleKeys = keys.take(keys.length - maxSnapshots);
    for (final key in staleKeys) {
      await _hive.entrySnapshotsBox.delete(key);
    }
    await _hive.entrySnapshotsBox.flush();
  }

  Future<List<OvertimeEntry>> _restoreLatestNonEmptySnapshot({
    bool allowOlderSnapshots = false,
  }) async {
    final entries = _entriesFromSnapshot(
      _latestSnapshot(allowOlderSnapshots: allowOlderSnapshots),
    );
    if (entries.isEmpty) return [];

    for (final entry in entries) {
      await _hive.entriesBox.put(entry.id, entry.toJson());
    }
    await _hive.entriesBox.flush();
    await _writeAuditEvent(
      action: 'restore',
      entryId: '*',
      description: '${entries.length} mesai kaydı yedekten geri yüklendi.',
    );
    await _writeSnapshot(reason: 'self_heal_restore');
    return entries;
  }

  Map<dynamic, dynamic>? _latestSnapshot({required bool allowOlderSnapshots}) {
    final key = _hive.integrityBox.get(AppConstants.latestEntrySnapshotKey);
    if (!allowOlderSnapshots) {
      final snapshot = key == null ? null : _hive.entrySnapshotsBox.get(key);
      return snapshot is Map ? snapshot : null;
    }

    final keys = _hive.entrySnapshotsBox.keys.cast<String>().toList()
      ..sort((a, b) => b.compareTo(a));
    for (final snapshotKey in keys) {
      final snapshot = _hive.entrySnapshotsBox.get(snapshotKey);
      if (_entriesFromSnapshot(snapshot).isNotEmpty) {
        return snapshot as Map<dynamic, dynamic>;
      }
    }
    return null;
  }

  List<OvertimeEntry> _entriesFromSnapshot(dynamic snapshot) {
    if (snapshot is! Map) return [];
    final values = snapshot['entries'];
    if (values is! List || values.isEmpty) return [];

    return values.map(_tryParseEntry).whereType<OvertimeEntry>().toList();
  }

  bool _verifyEntriesDigest(List<OvertimeEntry> entries) {
    final stored = _hive.integrityBox.get(AppConstants.latestEntryDigestKey);
    if (stored == null) return true;
    return stored == _entriesDigest(entries);
  }

  String _entriesDigest(List<OvertimeEntry> entries) {
    final canonicalEntries =
        entries
            .map((entry) => IntegrityHashService.canonicalMap(entry.toJson()))
            .toList()
          ..sort();
    return IntegrityHashService.hash(
      IntegrityHashService.canonicalList(canonicalEntries),
    );
  }

  OvertimeAuditEvent? _tryParseAuditEvent(dynamic value) {
    try {
      return OvertimeAuditEvent.fromJson(value as Map<dynamic, dynamic>);
    } on Object {
      return null;
    }
  }

  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  DateTime? _latestDate(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isAfter(current)) return candidate;
    return current;
  }

  ArchivedOvertimeEntry? _tryParseArchiveItem(String key, dynamic value) {
    try {
      if (value is! Map) return null;
      final entryValue = value['entry'];
      if (entryValue is! Map) return null;
      return ArchivedOvertimeEntry(
        archiveKey: key,
        reason: value['reason'] as String,
        archivedAt: DateTime.parse(value['archivedAt'] as String),
        entry: OvertimeEntry.fromJson(entryValue),
      );
    } on Object {
      return null;
    }
  }
}
