import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';

part 'match_stats_model.g.dart';

/// Aggregated match statistics.
@JsonSerializable(checked: true, createToJson: false)
final class MatchStatsModel {
  const MatchStatsModel({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.played,
    required this.winRatePercent,
    required this.currentWinStreak,
    required this.bestWinStreak,
    required this.accuracyPercent,
    required this.avgAnswerTimeMs,
    required this.questionCount,
  });

  factory MatchStatsModel.fromJson(Map<String, dynamic> json) =>
      _$MatchStatsModelFromJson(json);

  @JsonKey(required: true)
  final int wins;

  @JsonKey(required: true)
  final int losses;

  @JsonKey(required: true)
  final int draws;

  @JsonKey(required: true)
  final int played;

  @JsonKey(required: true)
  final double? winRatePercent;

  @JsonKey(required: true)
  final int currentWinStreak;

  @JsonKey(required: true)
  final int bestWinStreak;

  @JsonKey(required: true)
  final double? accuracyPercent;

  @JsonKey(required: true)
  final int? avgAnswerTimeMs;

  @JsonKey(required: true)
  final int questionCount;

  MatchStatsEntity toEntity() {
    final int? avgMs = avgAnswerTimeMs;
    return MatchStatsEntity(
      wins: wins,
      losses: losses,
      draws: draws,
      played: played,
      winRatePercent: winRatePercent,
      currentWinStreak: currentWinStreak,
      bestWinStreak: bestWinStreak,
      accuracyPercent: accuracyPercent,
      avgAnswerTime: avgMs == null ? null : Duration(milliseconds: avgMs),
      questionCount: questionCount,
    );
  }
}
