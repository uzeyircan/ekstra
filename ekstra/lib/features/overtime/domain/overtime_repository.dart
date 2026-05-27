import 'package:ekstra/features/overtime/domain/archived_overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_audit_event.dart';
import 'package:ekstra/features/overtime/domain/overtime_data_health.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';

abstract class OvertimeRepository {
  Future<List<OvertimeEntry>> getAll();
  Future<OvertimeDataHealth> getDataHealth();
  Future<List<OvertimeAuditEvent>> getAuditTrail({int limit = 20});
  Future<List<ArchivedOvertimeEntry>> getDeletedEntries({int limit = 30});
  Future<void> upsert(OvertimeEntry entry);
  Future<void> delete(String id);
  Future<void> clear();
  Future<int> restoreLatestBackup();
  Future<void> restoreDeletedEntry(String archiveKey);
}
