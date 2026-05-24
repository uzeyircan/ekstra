import 'package:ekstra/features/overtime/domain/overtime_entry.dart';

abstract class OvertimeRepository {
  Future<List<OvertimeEntry>> getAll();
  Future<void> upsert(OvertimeEntry entry);
  Future<void> delete(String id);
  Future<void> clear();
}
