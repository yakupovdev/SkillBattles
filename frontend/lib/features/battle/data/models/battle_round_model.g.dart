// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_round_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleRoundModel _$BattleRoundModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BattleRoundModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'number',
      'isOvertimeRound',
      'startedAt',
      'deadline',
      'limitSeconds',
      'question',
      'mySelectedOptionId',
      'reveal',
    ],
  );
  final val = BattleRoundModel(
    id: $checkedConvert('id', (v) => v as String),
    number: $checkedConvert('number', (v) => (v as num).toInt()),
    isOvertimeRound: $checkedConvert('isOvertimeRound', (v) => v as bool),
    startedAt: $checkedConvert('startedAt', (v) => DateTime.parse(v as String)),
    deadline: $checkedConvert('deadline', (v) => DateTime.parse(v as String)),
    limitSeconds: $checkedConvert('limitSeconds', (v) => (v as num).toInt()),
    question: $checkedConvert(
      'question',
      (v) => QuestionModel.fromJson(v as Map<String, dynamic>),
    ),
    mySelectedOptionId: $checkedConvert(
      'mySelectedOptionId',
      (v) => v as String?,
    ),
    reveal: $checkedConvert(
      'reveal',
      (v) => v == null
          ? null
          : RoundRevealModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});
