import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';

part 'rank_progress_model.g.dart';

/// Progress inside the current rank tier.
@JsonSerializable(checked: true, createToJson: false)
final class RankProgressModel {
  const RankProgressModel({
    required this.rankCode,
    required this.rankName,
    required this.leagueCode,
    required this.divisionRpCurrent,
    required this.divisionRpTarget,
    required this.floorRating,
    required this.ceilingExclusive,
  });

  factory RankProgressModel.fromJson(Map<String, dynamic> json) =>
      _$RankProgressModelFromJson(json);

  @JsonKey(required: true)
  final String rankCode;

  @JsonKey(required: true)
  final String rankName;

  @JsonKey(required: true)
  final String leagueCode;

  @JsonKey(required: true)
  final int divisionRpCurrent;

  @JsonKey(required: true)
  final int? divisionRpTarget;

  @JsonKey(required: true)
  final int floorRating;

  @JsonKey(required: true)
  final int? ceilingExclusive;

  RankProgressEntity toEntity() => RankProgressEntity(
    rankCode: rankCode,
    rankName: rankName,
    leagueCode: leagueCode,
    divisionRpCurrent: divisionRpCurrent,
    divisionRpTarget: divisionRpTarget,
    floorRating: floorRating,
    ceilingExclusive: ceilingExclusive,
  );
}
