import 'package:equatable/equatable.dart';

/// Per-player saved outcome. Deltas of the two players need not sum to 0
/// (independent K factors and rounding).
final class ResultPlayerEntity extends Equatable {
  const ResultPlayerEntity({
    required this.id,
    required this.nickname,
    required this.isPro,
    required this.score,
    required this.correctCount,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.ratingDelta,
    required this.kFactor,
    required this.rankBefore,
    required this.rankAfter,
    required this.calibrationMatchesRemaining,
  });

  final String id;
  final String nickname;
  final bool isPro;
  final int score;
  final int correctCount;
  final int ratingBefore;

  /// Frozen at settlement: after a season rollover the current profile
  /// rating can differ.
  final int ratingAfter;
  final int ratingDelta;

  /// 0 for private/cancelled, 64 while calibrating, 32 afterwards.
  final int kFactor;
  final String rankBefore;
  final String rankAfter;
  final int calibrationMatchesRemaining;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    isPro,
    score,
    correctCount,
    ratingBefore,
    ratingAfter,
    ratingDelta,
    kFactor,
    rankBefore,
    rankAfter,
    calibrationMatchesRemaining,
  ];
}
