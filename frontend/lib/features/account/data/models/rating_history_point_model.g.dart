// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_history_point_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingHistoryPointModel _$RatingHistoryPointModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RatingHistoryPointModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'battleId',
      'seasonId',
      'finishedAt',
      'ratingBefore',
      'ratingAfter',
      'ratingDelta',
    ],
  );
  final val = RatingHistoryPointModel(
    battleId: $checkedConvert('battleId', (v) => v as String),
    seasonId: $checkedConvert('seasonId', (v) => v as String),
    finishedAt: $checkedConvert(
      'finishedAt',
      (v) => DateTime.parse(v as String),
    ),
    ratingBefore: $checkedConvert('ratingBefore', (v) => (v as num).toInt()),
    ratingAfter: $checkedConvert('ratingAfter', (v) => (v as num).toInt()),
    ratingDelta: $checkedConvert('ratingDelta', (v) => (v as num).toInt()),
  );
  return val;
});
