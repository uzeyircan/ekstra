import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';
import 'package:ekstra/features/shifts/domain/shift_assignment.dart';
import 'package:ekstra/features/shifts/domain/shift_template.dart';

class LocalShiftRepository {
  const LocalShiftRepository(this._hive);

  final HiveService _hive;

  Future<List<Shift>> getAll() async {
    if (_hive.shiftsBox.isEmpty) {
      await seedDefaults();
    }
    return _hive.shiftsBox.values
        .map((value) => Shift.fromJson(value as Map<dynamic, dynamic>))
        .toList();
  }

  Future<List<ShiftTemplate>> getTemplates() async {
    if (_hive.shiftTemplatesBox.isEmpty) {
      await seedTemplates();
    }
    return _hive.shiftTemplatesBox.values
        .map((value) => ShiftTemplate.fromJson(value as Map<dynamic, dynamic>))
        .toList();
  }

  Future<List<ShiftAssignment>> getAssignments({
    required int year,
    required int month,
  }) async {
    return _hive.shiftAssignmentsBox.values
        .map(
          (value) => ShiftAssignment.fromJson(value as Map<dynamic, dynamic>),
        )
        .where(
          (assignment) =>
              assignment.date.year == year && assignment.date.month == month,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> seedDefaults() async {
    const shifts = [
      Shift(
        id: 'morning',
        name: 'Sabah',
        startTime: '08:00',
        endTime: '16:00',
        color: 0xFF2ED573,
        isEnabled: true,
      ),
      Shift(
        id: 'evening',
        name: 'Akşam',
        startTime: '16:00',
        endTime: '00:00',
        color: 0xFFFF9F43,
        isEnabled: true,
      ),
      Shift(
        id: 'night',
        name: 'Gece',
        startTime: '00:00',
        endTime: '08:00',
        color: 0xFF70A1FF,
        isEnabled: true,
      ),
      Shift(
        id: 'custom',
        name: 'Özel vardiya',
        startTime: '09:00',
        endTime: '18:00',
        color: 0xFFA29BFE,
        isEnabled: false,
      ),
    ];

    for (final shift in shifts) {
      await _hive.shiftsBox.put(shift.id, shift.toJson());
    }
    await _hive.shiftsBox.flush();
  }

  Future<void> seedTemplates() async {
    final shifts = await getAll();
    for (final shift in shifts) {
      final template = ShiftTemplate(
        id: shift.id,
        name: shift.name,
        startTime: shift.startTime,
        endTime: shift.endTime,
        color: shift.color,
        isEnabled: shift.isEnabled,
      );
      await _hive.shiftTemplatesBox.put(template.id, template.toJson());
    }
    await _hive.shiftTemplatesBox.flush();
  }

  Future<void> save(Shift shift) async {
    await _hive.shiftsBox.put(shift.id, shift.toJson());
    await _hive.shiftTemplatesBox.put(
      shift.id,
      ShiftTemplate(
        id: shift.id,
        name: shift.name,
        startTime: shift.startTime,
        endTime: shift.endTime,
        color: shift.color,
        isEnabled: shift.isEnabled,
      ).toJson(),
    );
    await _hive.shiftsBox.flush();
    await _hive.shiftTemplatesBox.flush();
  }

  Future<void> saveTemplate(ShiftTemplate template) async {
    await _hive.shiftTemplatesBox.put(template.id, template.toJson());
    await _hive.shiftTemplatesBox.flush();
  }

  Future<void> replaceMonthAssignments({
    required int year,
    required int month,
    required List<ShiftAssignment> assignments,
  }) async {
    final keysToDelete = _hive.shiftAssignmentsBox.values
        .map(
          (value) => ShiftAssignment.fromJson(value as Map<dynamic, dynamic>),
        )
        .where(
          (assignment) =>
              assignment.date.year == year && assignment.date.month == month,
        )
        .map((assignment) => assignment.id)
        .toList();

    await _hive.shiftAssignmentsBox.deleteAll(keysToDelete);
    for (final assignment in assignments) {
      await _hive.shiftAssignmentsBox.put(assignment.id, assignment.toJson());
    }
    await _hive.shiftAssignmentsBox.flush();
  }
}
