import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/rating_history_point_entity.dart';

part 'rating_history_point_model.g.dart';

/// One settled ranked result (Pro only).
@JsonSerializable(checked: true, createToJson: false)
final class RatingHistoryPointModel {
  const RatingHistoryPointModel({
    required this.battleId,
    required this.seasonId,
    required this.finishedAt,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.ratingDelta,
  });

  factory RatingHistoryPointModel.fromJson(Map<String, dynamic> json) =>
      _$RatingHistoryPointModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String seasonId;

  @JsonKey(required: true)
  final DateTime finishedAt;

  @JsonKey(required: true)
  final int ratingBefore;

  @JsonKey(required: true)
  final int ratingAfter;

  @JsonKey(required: true)
  final int ratingDelta;

  RatingHistoryPointEntity toEntity() => RatingHistoryPointEntity(
    battleId: battleId,
    seasonId: seasonId,
    finishedAt: finishedAt,
    ratingBefore: ratingBefore,
    ratingAfter: ratingAfter,
    ratingDelta: ratingDelta,
  );
}
