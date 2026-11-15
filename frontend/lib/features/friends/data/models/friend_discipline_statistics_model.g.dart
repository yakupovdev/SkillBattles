// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_discipline_statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendDisciplineStatisticsModel _$FriendDisciplineStatisticsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FriendDisciplineStatisticsModel', json, ($checkedConvert) {
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
    ],
  );
  final val = FriendDisciplineStatisticsModel(
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
  );
  return val;
});
