import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
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
    if (existing != null) {
      await _archiveEntry(id: entry.id, value: existing, reason: 'upsert');
    }
    await _hive.entriesBox.put(entry.id, entry.toJson());
    await _hive.entriesBox.flush();
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
    await _writeSnapshot(reason: 'delete');
  }

  @override
  Future<void> clear() async {
    await _writeSnapshot(reason: 'before_clear');
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

  Future<void> _writeSnapshot({required String reason}) async {
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    final snapshot = {
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': _readPrimaryEntries().map((entry) => entry.toJson()).toList(),
    };
    await _hive.entrySnapshotsBox.put(key, snapshot);
    await _hive.integrityBox.put(AppConstants.latestEntrySnapshotKey, key);
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
}
