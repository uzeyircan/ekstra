import 'dart:async';

import 'package:ekstra/features/live_session/data/local_live_session_repository.dart';
import 'package:ekstra/features/live_session/domain/live_work_session.dart';
import 'package:ekstra/features/overtime/presentation/overtime_providers.dart';
import 'package:ekstra/features/settings/domain/user_settings.dart';
import 'package:ekstra/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final liveSessionRepositoryProvider = Provider<LocalLiveSessionRepository>((
  ref,
) {
  return LocalLiveSessionRepository(ref.watch(hiveServiceProvider));
});

final liveTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final liveSessionProvider =
    AsyncNotifierProvider<LiveSessionController, LiveWorkSession?>(
      LiveSessionController.new,
    );

class LiveSessionController extends AsyncNotifier<LiveWorkSession?> {
  LocalLiveSessionRepository get _repository =>
      ref.read(liveSessionRepositoryProvider);

  @override
  Future<LiveWorkSession?> build() => _repository.getActive();

  Future<void> start() async {
    final now = DateTime.now();
    final session = LiveWorkSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      totalBreakSeconds: 0,
    );
    await _repository.save(session);
    state = AsyncData(session);
  }

  Future<void> startBreak() async {
    final session = state.value;
    if (session == null || session.isOnBreak) return;
    final updated = session.copyWith(breakStartedAt: DateTime.now());
    await _repository.save(updated);
    state = AsyncData(updated);
  }

  Future<void> resume() async {
    final session = state.value;
    if (session == null || !session.isOnBreak) return;
    final now = DateTime.now();
    final breakSeconds =
        session.totalBreakSeconds +
        now.difference(session.breakStartedAt!).inSeconds;
    final updated = session.copyWith(
      totalBreakSeconds: breakSeconds,
      clearBreakStartedAt: true,
    );
    await _repository.save(updated);
    state = AsyncData(updated);
  }

  Future<double> finish(UserSettings settings) async {
    var session = state.value;
    if (session == null) return 0;
    if (session.isOnBreak) {
      await resume();
      session = state.value;
    }
    if (session == null) return 0;

    final hours = _roundToQuarter(session.netHours(DateTime.now()));
    if (hours >= 0.25) {
      await ref
          .read(overtimeEntriesProvider.notifier)
          .addQuickHours(
            date: session.startedAt,
            hours: hours,
            multiplier: settings.defaultMultiplier,
            hourlyRate: settings.hourlyRate,
          );
    }
    await _repository.clear();
    state = const AsyncData(null);
    return hours;
  }

  Future<void> discard() async {
    await _repository.clear();
    state = const AsyncData(null);
  }

  double _roundToQuarter(double value) {
    return (value * 4).round() / 4;
  }
}
