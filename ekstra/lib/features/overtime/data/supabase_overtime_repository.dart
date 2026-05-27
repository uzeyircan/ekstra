import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';

class SupabaseOvertimeRepository implements OvertimeRepository {
  const SupabaseOvertimeRepository();

  Never _notImplemented() {
    throw UnimplementedError('Supabase repository is a future placeholder.');
  }

  @override
  Future<void> clear() async => _notImplemented();

  @override
  Future<void> delete(String id) async => _notImplemented();

  @override
  Future<List<OvertimeEntry>> getAll() async => _notImplemented();

  @override
  Future<List<ArchivedOvertimeEntry>> getDeletedEntries({
    int limit = 30,
  }) async => _notImplemented();

  @override
  Future<List<OvertimeAuditEvent>> getAuditTrail({int limit = 20}) async =>
      _notImplemented();

  @override
  Future<OvertimeDataHealth> getDataHealth() async => _notImplemented();

  @override
  Future<int> restoreLatestBackup() async => _notImplemented();

  @override
  Future<void> restoreDeletedEntry(String archiveKey) async =>
      _notImplemented();

  @override
  Future<void> upsert(OvertimeEntry entry) async => _notImplemented();
}
