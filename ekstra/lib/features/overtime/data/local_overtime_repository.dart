import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';

class LocalOvertimeRepository implements OvertimeRepository {
  const LocalOvertimeRepository(this._hive);

  final HiveService _hive;

  @override
  Future<List<OvertimeEntry>> getAll() async {
    return _hive.entriesBox.values
        .map((value) => OvertimeEntry.fromJson(value as Map<dynamic, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> upsert(OvertimeEntry entry) async {
    await _hive.entriesBox.put(entry.id, entry.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _hive.entriesBox.delete(id);
  }

  @override
  Future<void> clear() async {
    await _hive.entriesBox.clear();
  }
}
