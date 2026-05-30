import 'package:ekstra/features/dashboard/domain/widget_summary.dart';
import 'package:ekstra/features/dashboard/domain/widget_summary_service.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:ekstra/features/shifts/presentation/shift_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final widgetSummaryProvider = Provider<WidgetSummary?>((ref) {
  final settings = ref.watch(settingsControllerProvider).value;
  final entries = ref.watch(overtimeEntriesProvider).value;
  final assignments = ref.watch(shiftAssignmentsProvider).value;
  if (settings == null || entries == null || assignments == null) return null;

  const service = WidgetSummaryService();
  return service.build(
    now: DateTime.now(),
    settings: settings,
    entries: entries,
    assignments: assignments,
  );
});
