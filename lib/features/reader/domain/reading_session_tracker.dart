/// Measures active reading time for one open book.
///
/// Time only counts while the reader is in the foreground and the user is
/// doing something (turning pages, scrolling, touching). A gap longer than
/// [idleCutoff] between two signals counts as [idleCutoff], so leaving the
/// phone on the table does not inflate streaks or reading time.
class ReadingSessionTracker {
  ReadingSessionTracker({this.idleCutoff = const Duration(minutes: 3)});

  final Duration idleCutoff;

  DateTime? _startedAt;
  DateTime? _lastSignal;
  Duration _active = Duration.zero;
  double? _startPercent;
  double _endPercent = 0;

  bool get isRunning => _lastSignal != null;
  Duration get activeTime => _active;

  /// Starts (or resumes) counting from [now].
  void resume(DateTime now, {required double percent}) {
    _startedAt ??= now;
    _startPercent ??= percent;
    _endPercent = percent;
    _lastSignal = now;
  }

  /// Records activity; the time since the previous signal is counted.
  void signal(DateTime now, {double? percent}) {
    if (percent != null) _endPercent = percent;
    final last = _lastSignal;
    if (last == null) return;
    _active += _bounded(now.difference(last));
    _lastSignal = now;
  }

  /// Stops counting (app backgrounded). Time up to [now] is kept.
  void pause(DateTime now) {
    signal(now);
    _lastSignal = null;
  }

  /// Ends the session and returns it, or null if nothing worth saving
  /// happened. Resets the tracker so it can be reused after resume.
  CompletedSession? finish(DateTime now) {
    if (isRunning) pause(now);
    final started = _startedAt;
    final result = started == null || _active.inSeconds < 5
        ? null
        : CompletedSession(
            startedAt: started,
            endedAt: now,
            duration: _active,
            startPercent: _startPercent ?? 0,
            endPercent: _endPercent,
          );
    _startedAt = null;
    _startPercent = null;
    _active = Duration.zero;
    return result;
  }

  Duration _bounded(Duration gap) {
    if (gap.isNegative) return Duration.zero;
    return gap > idleCutoff ? idleCutoff : gap;
  }
}

class CompletedSession {
  const CompletedSession({
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.startPercent,
    required this.endPercent,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final double startPercent;
  final double endPercent;
}
