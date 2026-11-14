import 'package:equatable/equatable.dart';

/// A player inside a battle. [score], [correctCount] and [streak] include
/// revealed rounds only.
final class BattlePlayerEntity extends Equatable {
  const BattlePlayerEntity({
    required this.id,
    required this.nickname,
    required this.isPro,
    required this.rating,
    required this.rankCode,
    required this.ready,
    required this.connected,
    required this.reconnectDeadline,
    required this.score,
    required this.correctCount,
    required this.streak,
    required this.answeredCurrentRound,
  });

  final String id;
  final String nickname;
  final bool isPro;

  /// Frozen pre-match rating.
  final int rating;
  final String rankCode;
  final bool ready;
  final bool connected;

  /// End of the reconnect grace while [connected] is false.
  final DateTime? reconnectDeadline;
  final int score;
  final int correctCount;

  /// In-battle correct-answer streak.
  final int streak;

  /// Known immediately; correctness only after the reveal.
  final bool answeredCurrentRound;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    isPro,
    rating,
    rankCode,
    ready,
    connected,
    reconnectDeadline,
    score,
    correctCount,
    streak,
    answeredCurrentRound,
  ];
}
