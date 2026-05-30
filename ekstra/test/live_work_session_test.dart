import 'package:ekstra/features/live_session/domain/live_work_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live work session calculates net seconds excluding breaks', () {
    final session = LiveWorkSession(
      id: 'live-1',
      startedAt: DateTime(2026, 5, 27, 10),
      totalBreakSeconds: 600,
    );

    final netSeconds = session.netSeconds(DateTime(2026, 5, 27, 12));

    expect(netSeconds, 6600);
  });

  test('active break is included in break seconds', () {
    final session = LiveWorkSession(
      id: 'live-1',
      startedAt: DateTime(2026, 5, 27, 10),
      totalBreakSeconds: 300,
      breakStartedAt: DateTime(2026, 5, 27, 11),
    );

    final breakSeconds = session.breakSeconds(DateTime(2026, 5, 27, 11, 10));

    expect(breakSeconds, 900);
  });
}
