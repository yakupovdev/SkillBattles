import 'dart:async';

import 'package:test/test.dart';

/// Stand-in for the fake clock of `testWidgets` (flutter_test is not
/// available and `package:fake_async` is not a dependency).
///
/// Inside [fakeTimersTest] every [Timer] with a positive duration and every
/// periodic timer is fake: it fires only when [pump] moves the clock past
/// its deadline. Zero-duration timers and microtasks stay real, so `await`,
/// streams and futures behave as usual and `pump()` without a duration lets
/// one event-loop turn run, like `WidgetTester.pump()`.
final class FakeTimers {
  Duration _elapsed = Duration.zero;
  int _sequence = 0;
  final List<_FakeTimer> _timers = <_FakeTimer>[];

  /// Time moved by [pump] since the test started.
  Duration get elapsed => _elapsed;

  /// Fake timers that have not fired (or are periodic) and are not
  /// cancelled.
  int get pendingTimers => _timers.length;

  /// Moves the fake clock by [duration], firing every due timer in deadline
  /// order and letting an event-loop turn run after each, then once more.
  Future<void> pump([Duration duration = Duration.zero]) async {
    final Duration target = _elapsed + duration;
    while (true) {
      final _FakeTimer? next = _nextDue(target);
      if (next == null) break;
      if (next.deadline > _elapsed) _elapsed = next.deadline;
      next.fire();
      await _turn();
    }
    _elapsed = target;
    await _turn();
  }

  _FakeTimer? _nextDue(Duration target) {
    _FakeTimer? best;
    for (final _FakeTimer timer in _timers) {
      if (timer.deadline > target) continue;
      if (best == null ||
          timer.deadline < best.deadline ||
          (timer.deadline == best.deadline &&
              timer.sequence < best.sequence)) {
        best = timer;
      }
    }
    return best;
  }

  /// A real zero-delay timer: the zone hands it to the parent zone.
  static Future<void> _turn() => Future<void>.delayed(Duration.zero);

  Timer _create(Duration duration, void Function() callback) {
    final _FakeTimer timer = _FakeTimer(
      owner: this,
      deadline: _elapsed + duration,
      sequence: _sequence++,
      period: null,
      callback: (_) => callback(),
    );
    _timers.add(timer);
    return timer;
  }

  Timer _createPeriodic(Duration period, void Function(Timer timer) callback) {
    final Duration step = period < const Duration(microseconds: 1)
        ? const Duration(microseconds: 1)
        : period;
    final _FakeTimer timer = _FakeTimer(
      owner: this,
      deadline: _elapsed + step,
      sequence: _sequence++,
      period: step,
      callback: callback,
    );
    _timers.add(timer);
    return timer;
  }

  /// Runs [body] in a zone whose positive-duration timers are fake.
  Future<T> run<T>(Future<T> Function() body) {
    return runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        createTimer:
            (
              Zone self,
              ZoneDelegate parent,
              Zone zone,
              Duration duration,
              void Function() f,
            ) {
              if (duration <= Duration.zero) {
                return parent.createTimer(zone, duration, f);
              }
              return _create(duration, f);
            },
        createPeriodicTimer:
            (
              Zone self,
              ZoneDelegate parent,
              Zone zone,
              Duration period,
              void Function(Timer timer) f,
            ) => _createPeriodic(period, f),
      ),
    );
  }
}

final class _FakeTimer implements Timer {
  _FakeTimer({
    required this.owner,
    required this.deadline,
    required this.sequence,
    required this.period,
    required this.callback,
  });

  final FakeTimers owner;
  Duration deadline;
  int sequence;
  final Duration? period;
  final void Function(Timer timer) callback;
  int _tick = 0;
  bool _active = true;

  void fire() {
    _tick++;
    if (period == null) {
      _active = false;
      owner._timers.remove(this);
    } else {
      deadline += period!;
      sequence = owner._sequence++;
    }
    callback(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _active = false;
    owner._timers.remove(this);
  }
}

/// A [test] whose body runs under [FakeTimers]; replaces a `testWidgets`
/// that only used `tester.pump` to drive fake time.
void fakeTimersTest(
  String description,
  Future<void> Function(FakeTimers tester) body,
) {
  test(description, () {
    final FakeTimers timers = FakeTimers();
    return timers.run(() => body(timers));
  });
}
