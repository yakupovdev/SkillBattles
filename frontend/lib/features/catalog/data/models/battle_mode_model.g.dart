// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_mode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleModeModel _$BattleModeModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BattleModeModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'disciplineCode',
      'displayName',
      'description',
      'active',
      'format',
      'questionType',
      'optionsCount',
      'questionCount',
      'baseQuestionSeconds',
      'difficultyTimings',
      'difficultySchedules',
      'overtimeSeconds',
      'readyTimeoutSeconds',
      'countdownSeconds',
      'revealSeconds',
      'reconnectGraceSeconds',
      'contentAvailable',
    ],
  );
  final val = BattleModeModel(
    disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
    displayName: $checkedConvert('displayName', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String),
    active: $checkedConvert('active', (v) => v as bool),
    format: $checkedConvert(
      'format',
      (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
    ),
    questionType: $checkedConvert('questionType', (v) => v as String),
    optionsCount: $checkedConvert('optionsCount', (v) => (v as num).toInt()),
    questionCount: $checkedConvert('questionCount', (v) => (v as num).toInt()),
    baseQuestionSeconds: $checkedConvert(
      'baseQuestionSeconds',
      (v) => (v as num).toInt(),
    ),
    difficultyTimings: $checkedConvert(
      'difficultyTimings',
      (v) => (v as List<dynamic>)
          .map((e) => DifficultyTimingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    difficultySchedules: $checkedConvert(
      'difficultySchedules',
      (v) => (v as List<dynamic>)
          .map(
            (e) => DifficultyScheduleModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    overtimeSeconds: $checkedConvert(
      'overtimeSeconds',
      (v) => (v as num).toInt(),
    ),
    readyTimeoutSeconds: $checkedConvert(
      'readyTimeoutSeconds',
      (v) => (v as num).toInt(),
    ),
    countdownSeconds: $checkedConvert(
      'countdownSeconds',
      (v) => (v as num).toInt(),
    ),
    revealSeconds: $checkedConvert('revealSeconds', (v) => (v as num).toInt()),
    reconnectGraceSeconds: $checkedConvert(
      'reconnectGraceSeconds',
      (v) => (v as num).toInt(),
    ),
    contentAvailable: $checkedConvert('contentAvailable', (v) => v as bool),
  );
  return val;
});

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};
