// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difficulty_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DifficultyScheduleModel _$DifficultyScheduleModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DifficultyScheduleModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'minRating',
      'maxRatingExclusive',
      'roundDifficulties',
      'contentAvailable',
    ],
  );
  final val = DifficultyScheduleModel(
    minRating: $checkedConvert('minRating', (v) => (v as num).toInt()),
    maxRatingExclusive: $checkedConvert(
      'maxRatingExclusive',
      (v) => (v as num?)?.toInt(),
    ),
    roundDifficulties: $checkedConvert(
      'roundDifficulties',
      (v) => (v as List<dynamic>)
          .map((e) => $enumDecode(_$DifficultyModelEnumMap, e))
          .toList(),
    ),
    contentAvailable: $checkedConvert('contentAvailable', (v) => v as bool),
  );
  return val;
});

const _$DifficultyModelEnumMap = {
  DifficultyModel.easy: 'EASY',
  DifficultyModel.medium: 'MEDIUM',
  DifficultyModel.hard: 'HARD',
};
