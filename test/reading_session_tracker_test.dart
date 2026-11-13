import 'package:bookmunity/features/reader/domain/reading_session_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 13, 20);

  test('counts active time between signals', () {
    final tracker = ReadingSessionTracker()..resume(t0, percent: 10);
    tracker.signal(t0.add(const Duration(minutes: 1)));
    tracker.signal(t0.add(const Duration(minutes: 2)), percent: 14);
    final session = tracker.finish(t0.add(const Duration(minutes: 2, seconds: 30)));
    expect(session, isNotNull);
    expect(session!.duration, const Duration(minutes: 2, seconds: 30));
    expect(session.startPercent, 10);
    expect(session.endPercent, 14);
  });

  test('caps idle gaps so an abandoned phone does not count', () {
    final tracker = ReadingSessionTracker(idleCutoff: const Duration(minutes: 3))
      ..resume(t0, percent: 0);
    tracker.signal(t0.add(const Duration(hours: 2)));
    expect(tracker.activeTime, const Duration(minutes: 3));
  });

  test('time while paused is not counted', () {
    final tracker = ReadingSessionTracker()..resume(t0, percent: 0);
    tracker.pause(t0.add(const Duration(minutes: 1)));
    tracker.signal(t0.add(const Duration(minutes: 30)));
    tracker.resume(t0.add(const Duration(minutes: 30)), percent: 0);
    tracker.signal(t0.add(const Duration(minutes: 31)));
    expect(tracker.activeTime, const Duration(minutes: 2));
  });

  test('very short sessions are dropped and the tracker resets', () {
    final tracker = ReadingSessionTracker()..resume(t0, percent: 0);
    expect(tracker.finish(t0.add(const Duration(seconds: 3))), isNull);
    expect(tracker.activeTime, Duration.zero);
    expect(tracker.isRunning, isFalse);
  });

  test('finishing without resume yields nothing', () {
    expect(ReadingSessionTracker().finish(t0), isNull);
  });
}
