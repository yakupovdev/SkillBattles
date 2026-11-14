import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/difficulty_model.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/features/catalog/domain/entity/difficulty_schedule_entity.dart';

part 'difficulty_schedule_model.g.dart';

/// Difficulty bracket for a rating range.
@JsonSerializable(checked: true, createToJson: false)
final class DifficultyScheduleModel {
  const DifficultyScheduleModel({
    required this.minRating,
    required this.maxRatingExclusive,
    required this.roundDifficulties,
    required this.contentAvailable,
  });

  factory DifficultyScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$DifficultyScheduleModelFromJson(json);

  @JsonKey(required: true)
  final int minRating;

  @JsonKey(required: true)
  final int? maxRatingExclusive;

  @JsonKey(required: true)
  final List<DifficultyModel> roundDifficulties;

  @JsonKey(required: true)
  final bool contentAvailable;

  DifficultyScheduleEntity toEntity() => DifficultyScheduleEntity(
    minRating: minRating,
    maxRatingExclusive: maxRatingExclusive,
    roundDifficulties: List<Difficulty>.unmodifiable(
      roundDifficulties.map((DifficultyModel d) => d.toEntity()),
    ),
    contentAvailable: contentAvailable,
  );
}
