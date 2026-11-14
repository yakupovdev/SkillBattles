// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineStatsModel _$DisciplineStatsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DisciplineStatsModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'disciplineCode',
      'rating',
      'rank',
      'calibration',
      'allTimePeakRating',
      'allTimePeakRankCode',
      'seasonId',
      'seasonPeakRating',
      'seasonPeakRankCode',
      'seasonRolloverPending',
      'ranked',
      'privateMatches',
      'topicStats',
      'ratingHistory',
    ],
  );
  final val = DisciplineStatsModel(
    disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
    rating: $checkedConvert('rating', (v) => (v as num).toInt()),
    rank: $checkedConvert(
      'rank',
      (v) => RankProgressModel.fromJson(v as Map<String, dynamic>),
    ),
    calibration: $checkedConvert(
      'calibration',
      (v) => CalibrationModel.fromJson(v as Map<String, dynamic>),
    ),
    allTimePeakRating: $checkedConvert(
      'allTimePeakRating',
      (v) => (v as num).toInt(),
    ),
    allTimePeakRankCode: $checkedConvert(
      'allTimePeakRankCode',
      (v) => v as String,
    ),
    seasonId: $checkedConvert('seasonId', (v) => v as String),
    seasonPeakRating: $checkedConvert(
      'seasonPeakRating',
      (v) => (v as num).toInt(),
    ),
    seasonPeakRankCode: $checkedConvert(
      'seasonPeakRankCode',
      (v) => v as String,
    ),
    seasonRolloverPending: $checkedConvert(
      'seasonRolloverPending',
      (v) => v as bool,
    ),
    ranked: $checkedConvert(
      'ranked',
      (v) => MatchStatsModel.fromJson(v as Map<String, dynamic>),
    ),
    privateMatches: $checkedConvert(
      'privateMatches',
      (v) => MatchStatsModel.fromJson(v as Map<String, dynamic>),
    ),
    topicStats: $checkedConvert(
      'topicStats',
      (v) => (v as List<dynamic>?)
          ?.map((e) => TopicStatsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    ratingHistory: $checkedConvert(
      'ratingHistory',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => RatingHistoryPointModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});
