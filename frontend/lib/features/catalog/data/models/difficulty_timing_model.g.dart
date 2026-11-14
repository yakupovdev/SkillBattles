// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difficulty_timing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DifficultyTimingModel _$DifficultyTimingModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DifficultyTimingModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['difficulty', 'limitSeconds', 'basePoints'],
  );
  final val = DifficultyTimingModel(
    difficulty: $checkedConvert(
      'difficulty',
      (v) => $enumDecode(_$DifficultyModelEnumMap, v),
    ),
    limitSeconds: $checkedConvert('limitSeconds', (v) => (v as num).toInt()),
    basePoints: $checkedConvert('basePoints', (v) => (v as num).toInt()),
  );
  return val;
});

const _$DifficultyModelEnumMap = {
  DifficultyModel.easy: 'EASY',
  DifficultyModel.medium: 'MEDIUM',
  DifficultyModel.hard: 'HARD',
};
