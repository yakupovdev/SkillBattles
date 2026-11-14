import 'package:equatable/equatable.dart';

/// One player's revealed answer and server-computed points.
///
/// The opponent's [selectedOptionId] is `null` for Free readers, even when
/// the opponent was correct.
final class RoundAnswerEntity extends Equatable {
  const RoundAnswerEntity({
    required this.userId,
    required this.selectedOptionId,
    required this.correct,
    required this.elapsed,
    required this.basePoints,
    required this.speedBonus,
    required this.streakBonus,
    required this.tieBreakPoints,
    required this.points,
    required this.timedOut,
  });

  final String userId;
  final String? selectedOptionId;
  final bool correct;

  /// `null` without an answer.
  final Duration? elapsed;
  final int basePoints;
  final int speedBonus;
  final int streakBonus;

  /// 1 only for the overtime winner.
  final int tieBreakPoints;
  final int points;
  final bool timedOut;

  @override
  List<Object?> get props => <Object?>[
    userId,
    selectedOptionId,
    correct,
    elapsed,
    basePoints,
    speedBonus,
    streakBonus,
    tieBreakPoints,
    points,
    timedOut,
  ];
}
