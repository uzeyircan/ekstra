import 'package:ekstra/core/storage/hive_service.dart';
import 'package:ekstra/features/shifts/domain/shift.dart';

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
}
