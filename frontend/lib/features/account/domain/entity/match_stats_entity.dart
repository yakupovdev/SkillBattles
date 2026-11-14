import 'package:equatable/equatable.dart';

/// Basic statistics over the whole history (Free and Pro). A `null` value
/// means "no data yet" and is never shown as 0.
final class MatchStatsEntity extends Equatable {
  const MatchStatsEntity({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.played,
    required this.winRatePercent,
    required this.currentWinStreak,
    required this.bestWinStreak,
    required this.accuracyPercent,
    required this.avgAnswerTime,
    required this.questionCount,
  });

  final int wins;
  final int losses;
  final int draws;
  final int played;
  final double? winRatePercent;
  final int currentWinStreak;
  final int bestWinStreak;
  final double? accuracyPercent;
  final Duration? avgAnswerTime;
  final int questionCount;

  @override
  List<Object?> get props => <Object?>[
    wins,
    losses,
    draws,
    played,
    winRatePercent,
    currentWinStreak,
    bestWinStreak,
    accuracyPercent,
    avgAnswerTime,
    questionCount,
  ];
}
