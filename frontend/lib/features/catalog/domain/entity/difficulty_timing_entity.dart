import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/difficulty.dart';

final class DifficultyTimingEntity extends Equatable {
  const DifficultyTimingEntity({
    required this.difficulty,
    required this.limitSeconds,
    required this.basePoints,
  });

  final Difficulty difficulty;
  final int limitSeconds;
  final int basePoints;

  @override
  List<Object?> get props => <Object?>[difficulty, limitSeconds, basePoints];
}
