import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/difficulty_model.dart';
import 'package:skill_battles/features/catalog/domain/entity/difficulty_timing_entity.dart';

part 'difficulty_timing_model.g.dart';

/// Time limit and base points of a difficulty.
@JsonSerializable(checked: true, createToJson: false)
final class DifficultyTimingModel {
  const DifficultyTimingModel({
    required this.difficulty,
    required this.limitSeconds,
    required this.basePoints,
  });

  factory DifficultyTimingModel.fromJson(Map<String, dynamic> json) =>
      _$DifficultyTimingModelFromJson(json);

  @JsonKey(required: true)
  final DifficultyModel difficulty;

  @JsonKey(required: true)
  final int limitSeconds;

  @JsonKey(required: true)
  final int basePoints;

  DifficultyTimingEntity toEntity() => DifficultyTimingEntity(
    difficulty: difficulty.toEntity(),
    limitSeconds: limitSeconds,
    basePoints: basePoints,
  );
}
