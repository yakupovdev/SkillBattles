import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/difficulty.dart';

/// Five ordered main-round difficulties for a lower-rating bracket. Never
/// shown before the match (the countdown hides the grid).
final class DifficultyScheduleEntity extends Equatable {
  const DifficultyScheduleEntity({
    required this.minRating,
    required this.maxRatingExclusive,
    required this.roundDifficulties,
    required this.contentAvailable,
  });

  final int minRating;
  final int? maxRatingExclusive;
  final List<Difficulty> roundDifficulties;
  final bool contentAvailable;

  @override
  List<Object?> get props => <Object?>[
    minRating,
    maxRatingExclusive,
    roundDifficulties,
    contentAvailable,
  ];
}
