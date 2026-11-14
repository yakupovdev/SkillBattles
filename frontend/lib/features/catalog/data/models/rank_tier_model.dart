import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/catalog/domain/entity/rank_tier_entity.dart';

part 'rank_tier_model.g.dart';

/// Rank threshold served by GET /ranks.
@JsonSerializable(checked: true, createToJson: false)
final class RankTierModel {
  const RankTierModel({
    required this.code,
    required this.displayName,
    required this.leagueCode,
    required this.floorRating,
    required this.ceilingExclusive,
    required this.divisionNumber,
  });

  factory RankTierModel.fromJson(Map<String, dynamic> json) =>
      _$RankTierModelFromJson(json);

  @JsonKey(required: true)
  final String code;

  @JsonKey(required: true)
  final String displayName;

  @JsonKey(required: true)
  final String leagueCode;

  @JsonKey(required: true)
  final int floorRating;

  @JsonKey(required: true)
  final int? ceilingExclusive;

  @JsonKey(required: true)
  final int? divisionNumber;

  RankTierEntity toEntity() => RankTierEntity(
    code: code,
    displayName: displayName,
    leagueCode: leagueCode,
    floorRating: floorRating,
    ceilingExclusive: ceilingExclusive,
    divisionNumber: divisionNumber,
  );
}
