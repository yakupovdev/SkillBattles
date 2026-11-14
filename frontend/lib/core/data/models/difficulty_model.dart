import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/difficulty.dart';

/// Question difficulty.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum DifficultyModel {
  easy,
  medium,
  hard;

  Difficulty toEntity() => switch (this) {
    DifficultyModel.easy => Difficulty.easy,
    DifficultyModel.medium => Difficulty.medium,
    DifficultyModel.hard => Difficulty.hard,
  };
}
