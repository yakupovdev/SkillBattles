// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleReviewModel _$BattleReviewModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BattleReviewModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'battleId',
          'disciplineCode',
          'mode',
          'rulesVersion',
          'mistakesOnly',
          'answerAccess',
          'rounds',
        ],
      );
      final val = BattleReviewModel(
        battleId: $checkedConvert('battleId', (v) => v as String),
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        mode: $checkedConvert(
          'mode',
          (v) => $enumDecode(_$CompetitionModeModelEnumMap, v),
        ),
        rulesVersion: $checkedConvert('rulesVersion', (v) => v as String),
        mistakesOnly: $checkedConvert('mistakesOnly', (v) => v as bool),
        answerAccess: $checkedConvert(
          'answerAccess',
          (v) => AnswerAccessModel.fromJson(v as Map<String, dynamic>),
        ),
        rounds: $checkedConvert(
          'rounds',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewRoundModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

const _$CompetitionModeModelEnumMap = {
  CompetitionModeModel.ranked: 'RANKED',
  CompetitionModeModel.private: 'PRIVATE',
};
