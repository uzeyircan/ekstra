import 'package:ekstra/core/constants/app_constants.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/sync/domain/cloud_sync_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudBackupService {
  const CloudBackupService({required HiveService hive, SupabaseClient? client})
    : _hive = hive,
      _client = client;

  final HiveService _hive;
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<CloudSyncResult> upload() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Bulut yedekleme icin once giris yap.');
    }

    final backup = _buildSnapshot(user.id);
    await _supabase.from('user_cloud_backups').upsert({
      'user_id': user.id,
      'backup': backup,
    });
    await _markSynced();

    final entries = (backup['entries'] as List).length;
    final dayStatuses = (backup['dayStatuses'] as List).length;
    return CloudSyncResult(
      message:
          '$entries mesai kaydi ve $dayStatuses gun durumu buluta yedeklendi.',
      entryCount: entries,
      changedCount: entries + dayStatuses,
    );
  }

  Future<CloudSyncResult> restoreMissing() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Buluttan geri yukleme icin once giris yap.');
    }

    final response = await _supabase
        .from('user_cloud_backups')
        .select('backup')
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null) {
      return const CloudSyncResult(
        message: 'Bulutta henuz yedek yok.',
        entryCount: 0,
        changedCount: 0,
      );
    }

    final backup = Map<String, dynamic>.from(response['backup'] as Map);
    final changed = await _mergeSnapshot(backup);
    await _markSynced();

    return CloudSyncResult(
      message: changed == 0
          ? 'Bulut yedegi kontrol edildi. Yeni veri bulunmadi.'
          : '$changed kayit buluttan cihaza eklendi/guncellendi.',
      entryCount: _hive.entriesBox.length,
      changedCount: changed,
    );
  }

  Map<String, dynamic> _buildSnapshot(String userId) {
    return {
      'version': 1,
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': _jsonOrNull(_hive.settingsBox.get(AppConstants.settingsKey)),
      'entries': _boxValues(_hive.entriesBox),
      'shifts': _boxValues(_hive.shiftsBox),
      'shiftTemplates': _boxValues(_hive.shiftTemplatesBox),
      'shiftAssignments': _boxValues(_hive.shiftAssignmentsBox),
      'dayStatuses': _boxValues(_hive.dayStatusesBox),
      'payrollChecks': _boxValues(_hive.payrollChecksBox),
      'payrollLocks': _boxValues(_hive.payrollLocksBox),
    };
  }

  Future<int> _mergeSnapshot(Map<String, dynamic> backup) async {
    var changed = 0;
    changed += await _mergeEntries(backup['entries']);
    changed += await _mergeMissingList(_hive.shiftsBox, backup['shifts']);
    changed += await _mergeMissingList(
      _hive.shiftTemplatesBox,
      backup['shiftTemplates'],
    );
    changed += await _mergeMissingList(
      _hive.shiftAssignmentsBox,
      backup['shiftAssignments'],
    );
    changed += await _mergeMissingList(
      _hive.dayStatusesBox,
      backup['dayStatuses'],
    );
    changed += await _mergeMissingList(
      _hive.payrollChecksBox,
      backup['payrollChecks'],
    );
    changed += await _mergeMissingList(
      _hive.payrollLocksBox,
      backup['payrollLocks'],
    );
    changed += await _mergeSettings(backup['settings']);
    await Future.wait([
      _hive.entriesBox.flush(),
      _hive.shiftsBox.flush(),
      _hive.shiftTemplatesBox.flush(),
      _hive.shiftAssignmentsBox.flush(),
      _hive.dayStatusesBox.flush(),
      _hive.payrollChecksBox.flush(),
      _hive.payrollLocksBox.flush(),
      _hive.settingsBox.flush(),
    ]);
    return changed;
  }

  Future<int> _mergeEntries(dynamic values) async {
    if (values is! List) return 0;
    var changed = 0;
    for (final value in values) {
      if (value is! Map) continue;
      final remote = Map<String, dynamic>.from(value);
      final id = remote['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final localValue = _hive.entriesBox.get(id);
      if (localValue == null || _remoteEntryIsNewer(remote, localValue)) {
        await _hive.entriesBox.put(id, remote);
        changed++;
      }
    }
    return changed;
  }

  bool _remoteEntryIsNewer(Map<String, dynamic> remote, dynamic localValue) {
    try {
      final local = OvertimeEntry.fromJson(localValue as Map<dynamic, dynamic>);
      final remoteUpdatedAt = DateTime.tryParse(
        (remote['updatedAt'] as String?) ?? '',
      );
      return remoteUpdatedAt != null &&
          remoteUpdatedAt.isAfter(local.updatedAt);
    } on Object {
      return true;
    }
  }

  Future<int> _mergeMissingList(dynamic box, dynamic values) async {
    if (values is! List) return 0;
    var changed = 0;
    for (final value in values) {
      if (value is! Map) continue;
      final item = Map<String, dynamic>.from(value);
      final id = item['id'] as String?;
      if (id == null || id.isEmpty || box.containsKey(id)) continue;
      await box.put(id, item);
      changed++;
    }
    return changed;
  }

  Future<int> _mergeSettings(dynamic value) async {
    if (value is! Map) return 0;
    if (_hive.settingsBox.containsKey(AppConstants.settingsKey)) return 0;
    await _hive.settingsBox.put(
      AppConstants.settingsKey,
      Map<String, dynamic>.from(value),
    );
    return 1;
  }

  List<Map<String, dynamic>> _boxValues(dynamic box) {
    return box.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  Map<String, dynamic>? _jsonOrNull(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<void> _markSynced() async {
    await _hive.integrityBox.put(
      AppConstants.latestCloudSyncAtKey,
      DateTime.now().toIso8601String(),
    );
    await _hive.integrityBox.flush();
  }
}
