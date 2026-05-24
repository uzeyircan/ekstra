import 'package:ekstra/core/services/date_key.dart';
import 'package:ekstra/features/overtime/data/local_overtime_repository.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_repository.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overtimeRepositoryProvider = Provider<OvertimeRepository>((ref) {
  return LocalOvertimeRepository(ref.watch(hiveServiceProvider));
});

final overtimeEntriesProvider =
    AsyncNotifierProvider<OvertimeEntriesController, List<OvertimeEntry>>(
  OvertimeEntriesController.new,
);

class OvertimeEntriesController extends AsyncNotifier<List<OvertimeEntry>> {
  OvertimeRepository get _repository => ref.read(overtimeRepositoryProvider);

  @override
  Future<List<OvertimeEntry>> build() => _repository.getAll();

  Future<void> upsertDay({
    required DateTime date,
    required double hours,
    required String note,
    required OvertimeType type,
    required double multiplier,
    String? existingId,
  }) async {
    final now = DateTime.now();
    final entry = OvertimeEntry(
      id: existingId ?? DateKey.fromDate(date),
      date: DateKey.onlyDate(date),
      hours: hours,
      note: note,
      overtimeType: type,
      multiplier: multiplier,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(entry);
    state = AsyncData(await _repository.getAll());
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = AsyncData(await _repository.getAll());
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const AsyncData([]);
  }
}
