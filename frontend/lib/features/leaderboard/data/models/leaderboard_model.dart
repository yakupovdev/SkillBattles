import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/season_model.dart';
import 'package:skill_battles/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';

part 'leaderboard_model.g.dart';

/// Current season top 50 plus own row.
@JsonSerializable(checked: true, createToJson: false)
final class LeaderboardModel {
  const LeaderboardModel({
    required this.disciplineCode,
    required this.season,
    required this.generatedAt,
    required this.top,
    required this.me,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardModelFromJson(json);

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final SeasonModel season;

  @JsonKey(required: true)
  final DateTime generatedAt;

  @JsonKey(required: true)
  final List<LeaderboardEntryModel> top;

  @JsonKey(required: true)
  final LeaderboardEntryModel? me;

  LeaderboardEntity toEntity() => LeaderboardEntity(
    disciplineCode: disciplineCode,
    season: season.toEntity(),
    generatedAt: generatedAt,
    top: top
        .map((LeaderboardEntryModel entry) => entry.toEntity())
        .toList(growable: false),
    me: me?.toEntity(),
  );
}
