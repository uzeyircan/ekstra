import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/day_status/data/local_day_status_repository.dart';
import 'package:ekstra/features/day_status/domain/day_status.dart';
import 'package:ekstra/features/day_status/domain/day_status_type.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dayStatusRepositoryProvider = Provider<LocalDayStatusRepository>((ref) {
  return LocalDayStatusRepository(ref.watch(hiveServiceProvider));
});

final dayStatusesProvider =
    AsyncNotifierProvider<DayStatusesController, List<DayStatus>>(
      DayStatusesController.new,
    );

class DayStatusesController extends AsyncNotifier<List<DayStatus>> {
  LocalDayStatusRepository get _repository =>
      ref.read(dayStatusRepositoryProvider);

  @override
  Future<List<DayStatus>> build() => _repository.getAll();

  Future<void> save({
    required DateTime date,
    required DayStatusType type,
    required String note,
  }) async {
    final now = DateTime.now();
    final normalizedDate = DateKey.onlyDate(date);
    final existing = await _repository.getByDate(normalizedDate);
    final status = DayStatus(
      id: DateKey.fromDate(normalizedDate),
      date: normalizedDate,
      type: type,
      note: note,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsert(status);
    state = AsyncData(await _repository.getAll());
  }

  Future<void> delete(DateTime date) async {
    await _repository.deleteByDate(date);
    state = AsyncData(await _repository.getAll());
  }
}
