import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/day_status/domain/day_status.dart';

class LocalDayStatusRepository {
  const LocalDayStatusRepository(this._hive);

  final HiveService _hive;

  Future<List<DayStatus>> getAll() async {
    return _hive.dayStatusesBox.values
        .map((value) => DayStatus.fromJson(value as Map<dynamic, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<DayStatus>> getMonth({
    required int year,
    required int month,
  }) async {
    final statuses = await getAll();
    return statuses
        .where(
          (status) => status.date.year == year && status.date.month == month,
        )
        .toList();
  }

  Future<DayStatus?> getByDate(DateTime date) async {
    final value = _hive.dayStatusesBox.get(DateKey.fromDate(date));
    if (value is! Map) return null;
    return DayStatus.fromJson(value);
  }

  Future<void> upsert(DayStatus status) async {
    await _hive.dayStatusesBox.put(status.id, status.toJson());
    await _hive.dayStatusesBox.flush();
  }

  Future<void> deleteByDate(DateTime date) async {
    await _hive.dayStatusesBox.delete(DateKey.fromDate(date));
    await _hive.dayStatusesBox.flush();
  }
}
