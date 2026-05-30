import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/shifts/data/local_shift_repository.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shiftRepositoryProvider = Provider<LocalShiftRepository>((ref) {
  return LocalShiftRepository(ref.watch(hiveServiceProvider));
});

final shiftsProvider = AsyncNotifierProvider<ShiftsController, List<Shift>>(
  ShiftsController.new,
);

class ShiftsController extends AsyncNotifier<List<Shift>> {
  LocalShiftRepository get _repository => ref.read(shiftRepositoryProvider);

  @override
  Future<List<Shift>> build() => _repository.getAll();

  Future<void> toggle(Shift shift, bool isEnabled) async {
    await _repository.save(
      Shift(
        id: shift.id,
        name: shift.name,
        startTime: shift.startTime,
        endTime: shift.endTime,
        color: shift.color,
        isEnabled: isEnabled,
      ),
    );
    state = AsyncData(await _repository.getAll());
  }
}
