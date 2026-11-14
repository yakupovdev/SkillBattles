import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/season_entity.dart';

/// Peak and final rating of a completed season.
final class SeasonPeakEntity extends Equatable {
  const SeasonPeakEntity({
    required this.season,
    required this.disciplineCode,
    required this.peakRating,
    required this.peakRankCode,
    required this.finalRating,
  });

  final SeasonEntity season;
  final String disciplineCode;
  final int peakRating;
  final String peakRankCode;
  final int finalRating;

  @override
  List<Object?> get props => <Object?>[
    season,
    disciplineCode,
    peakRating,
    peakRankCode,
    finalRating,
  ];
}
