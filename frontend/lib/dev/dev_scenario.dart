import 'package:flutter/foundation.dart';

/// How the mock opponent plays.
enum DevOpponent {
  /// Random mix of right and wrong answers.
  mixed('Mixed answers'),

  /// Always right, fast.
  alwaysCorrect('Always correct'),

  /// Always wrong.
  alwaysWrong('Always wrong'),

  /// Never answers (time-outs).
  timeout('Never answers'),

  /// Mirrors your correctness and points, so the five rounds end in a tie
  /// and overtime starts; in overtime it answers right but slower.
  overtimeWin('Tie → overtime (you can win)'),

  /// Mirrors you and misses the overtime question too: a draw if you miss.
  overtimeDraw('Tie → overtime (draw if you miss)'),

  /// Surrenders in round 3 (forfeit win, possibly with fewer points).
  surrenders('Surrenders in round 3'),

  /// Drops the connection in round 2 and never comes back.
  disconnects('Disconnects in round 2');

  const DevOpponent(this.label);

  final String label;
}

/// What a test checkout does.
enum DevPayment {
  activates('Payment succeeds'),
  staysPending('Payment stays pending');

  const DevPayment(this.label);

  final String label;
}

/// DEVELOPMENT ONLY. Knobs of the in-app mock backend. They never replace an
/// end-to-end check against the real backend.
final class DevScenario extends ChangeNotifier {
  DevOpponent _opponent = DevOpponent.mixed;
  DevPayment _payment = DevPayment.activates;
  bool _cancelNextRankedForQuota = false;

  DevOpponent get opponent => _opponent;
  DevPayment get payment => _payment;

  /// The next ranked battle is cancelled with QUOTA_EXHAUSTED at its start.
  bool get cancelNextRankedForQuota => _cancelNextRankedForQuota;

  /// Rebuilds the dev panel after a backend-side change.
  void touch() => notifyListeners();

  set opponent(DevOpponent value) {
    _opponent = value;
    notifyListeners();
  }

  set payment(DevPayment value) {
    _payment = value;
    notifyListeners();
  }

  set cancelNextRankedForQuota(bool value) {
    _cancelNextRankedForQuota = value;
    notifyListeners();
  }
}
