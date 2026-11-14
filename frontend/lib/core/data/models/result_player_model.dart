import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/result_player_entity.dart';

part 'result_player_model.g.dart';

/// Per-player result of a battle.
@JsonSerializable(checked: true, createToJson: false)
final class ResultPlayerModel {
  const ResultPlayerModel({
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

  factory ResultPlayerModel.fromJson(Map<String, dynamic> json) =>
      _$ResultPlayerModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String nickname;

  @JsonKey(required: true)
  final bool isPro;

  @JsonKey(required: true)
  final int score;

  @JsonKey(required: true)
  final int correctCount;

  @JsonKey(required: true)
  final int ratingBefore;

  @JsonKey(required: true)
  final int ratingAfter;

  @JsonKey(required: true)
  final int ratingDelta;

  @JsonKey(required: true)
  final int kFactor;

  @JsonKey(required: true)
  final String rankBefore;

  @JsonKey(required: true)
  final String rankAfter;

  @JsonKey(required: true)
  final int calibrationMatchesRemaining;

  ResultPlayerEntity toEntity() => ResultPlayerEntity(
    id: id,
    nickname: nickname,
    isPro: isPro,
    score: score,
    correctCount: correctCount,
    ratingBefore: ratingBefore,
    ratingAfter: ratingAfter,
    ratingDelta: ratingDelta,
    kFactor: kFactor,
    rankBefore: rankBefore,
    rankAfter: rankAfter,
    calibrationMatchesRemaining: calibrationMatchesRemaining,
  );
}
