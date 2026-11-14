import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/season_model.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';

part 'season_peak_model.g.dart';

/// Peak and final rating of a completed season.
@JsonSerializable(checked: true, createToJson: false)
final class SeasonPeakModel {
  const SeasonPeakModel({
    required this.season,
    required this.disciplineCode,
    required this.peakRating,
    required this.peakRankCode,
    required this.finalRating,
  });

  factory SeasonPeakModel.fromJson(Map<String, dynamic> json) =>
      _$SeasonPeakModelFromJson(json);

  @JsonKey(required: true)
  final SeasonModel season;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final int peakRating;

  @JsonKey(required: true)
  final String peakRankCode;

  @JsonKey(required: true)
  final int finalRating;

  SeasonPeakEntity toEntity() => SeasonPeakEntity(
    season: season.toEntity(),
    disciplineCode: disciplineCode,
    peakRating: peakRating,
    peakRankCode: peakRankCode,
    finalRating: finalRating,
  );
}
