import 'package:ekstra/features/overtime/domain/overtime_entry.dart';

class ArchivedOvertimeEntry {
  const ArchivedOvertimeEntry({
    required this.archiveKey,
    required this.reason,
    required this.archivedAt,
    required this.entry,
  });

  final String archiveKey;
  final String reason;
  final DateTime archivedAt;
  final OvertimeEntry entry;
}
