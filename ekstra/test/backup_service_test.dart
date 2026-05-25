import 'package:ekstra/core/services/backup_service.dart';
import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/overtime/domain/overtime_type.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup service exports and imports settings and entries', () {
    final settings = UserSettings.defaults().copyWith(
      hourlyRate: 100,
      hasCompletedOnboarding: true,
    );
    final entries = [
      OvertimeEntry(
        id: 'entry-1',
        date: DateTime(2026, 5, 24),
        hours: 3,
        note: 'test',
        overtimeType: OvertimeType.normal,
        multiplier: 1.5,
        createdAt: DateTime(2026, 5, 24),
        updatedAt: DateTime(2026, 5, 24),
      ),
    ];

    final exported = BackupService.exportJson(
      settings: settings,
      entries: entries,
    );
    final imported = BackupService.importJson(exported);

    expect(imported.settings.hourlyRate, 100);
    expect(imported.entries.single.id, 'entry-1');
    expect(imported.entries.single.hours, 3);
  });
}
