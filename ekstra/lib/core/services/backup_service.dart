import 'dart:convert';

import 'package:ekstra/features/overtime/domain/overtime_entry.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';

class BackupPayload {
  const BackupPayload({required this.settings, required this.entries});

  final UserSettings settings;
  final List<OvertimeEntry> entries;
}

class BackupService {
  const BackupService._();

  static const currentVersion = 1;

  static String exportJson({
    required UserSettings settings,
    required List<OvertimeEntry> entries,
  }) {
    final payload = {
      'app': 'EKSTRA',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static BackupPayload importJson(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Yedek formatı geçersiz.');
    }
    if (decoded['app'] != 'EKSTRA') {
      throw const FormatException('Bu dosya EKSTRA yedeği değil.');
    }

    final settingsValue = decoded['settings'];
    final entriesValue = decoded['entries'];
    if (settingsValue is! Map || entriesValue is! List) {
      throw const FormatException('Yedek içeriği eksik.');
    }

    return BackupPayload(
      settings: UserSettings.fromJson(
        settingsValue,
      ).copyWith(hasCompletedOnboarding: true),
      entries: entriesValue
          .whereType<Map>()
          .map((entry) => OvertimeEntry.fromJson(entry))
          .toList(),
    );
  }
}
