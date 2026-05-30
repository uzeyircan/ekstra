import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/shifts/data/local_shift_repository.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:ekstra/features/shifts/domain/shift_schedule_service.dart';
import 'package:ekstra/features/shifts/domain/shift_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shiftRepositoryProvider = Provider<LocalShiftRepository>((ref) {
  return LocalShiftRepository(ref.watch(hiveServiceProvider));
});

final shiftsProvider = AsyncNotifierProvider<ShiftsController, List<Shift>>(
  ShiftsController.new,
);

final shiftTemplatesProvider =
    AsyncNotifierProvider<ShiftTemplatesController, List<ShiftTemplate>>(
      ShiftTemplatesController.new,
    );

final shiftAssignmentsProvider =
    AsyncNotifierProvider<ShiftAssignmentsController, List<ShiftAssignment>>(
      ShiftAssignmentsController.new,
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
    ref.invalidate(shiftTemplatesProvider);
  }
}

class ShiftTemplatesController extends AsyncNotifier<List<ShiftTemplate>> {
  LocalShiftRepository get _repository => ref.read(shiftRepositoryProvider);

  @override
  Future<List<ShiftTemplate>> build() => _repository.getTemplates();
}

class ShiftAssignmentsController extends AsyncNotifier<List<ShiftAssignment>> {
  LocalShiftRepository get _repository => ref.read(shiftRepositoryProvider);

  @override
  Future<List<ShiftAssignment>> build() {
    final now = DateTime.now();
    return _repository.getAssignments(year: now.year, month: now.month);
  }

  Future<void> generateMonth({
    required DateTime month,
    required ShiftTemplate template,
    required ShiftRepeatType repeatType,
    required Set<int> selectedWeekdays,
    ShiftTemplate? alternateTemplate,
  }) async {
    const service = ShiftScheduleService();
    final assignments = service.buildMonthlyAssignments(
      template: template,
      month: month,
      repeatType: repeatType,
      selectedWeekdays: selectedWeekdays,
      alternateTemplate: alternateTemplate,
    );
    await _repository.replaceMonthAssignments(
      year: month.year,
      month: month.month,
      assignments: assignments,
    );
    state = AsyncData(
      await _repository.getAssignments(year: month.year, month: month.month),
    );
  }
}
