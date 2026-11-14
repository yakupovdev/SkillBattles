// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultPlayerModel _$ResultPlayerModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResultPlayerModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'nickname',
      'isPro',
      'score',
      'correctCount',
      'ratingBefore',
      'ratingAfter',
      'ratingDelta',
      'kFactor',
      'rankBefore',
      'rankAfter',
      'calibrationMatchesRemaining',
    ],
  );
  final val = ResultPlayerModel(
    id: $checkedConvert('id', (v) => v as String),
    nickname: $checkedConvert('nickname', (v) => v as String),
    isPro: $checkedConvert('isPro', (v) => v as bool),
    score: $checkedConvert('score', (v) => (v as num).toInt()),
    correctCount: $checkedConvert('correctCount', (v) => (v as num).toInt()),
    ratingBefore: $checkedConvert('ratingBefore', (v) => (v as num).toInt()),
    ratingAfter: $checkedConvert('ratingAfter', (v) => (v as num).toInt()),
    ratingDelta: $checkedConvert('ratingDelta', (v) => (v as num).toInt()),
    kFactor: $checkedConvert('kFactor', (v) => (v as num).toInt()),
    rankBefore: $checkedConvert('rankBefore', (v) => v as String),
    rankAfter: $checkedConvert('rankAfter', (v) => v as String),
    calibrationMatchesRemaining: $checkedConvert(
      'calibrationMatchesRemaining',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});
