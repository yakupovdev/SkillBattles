// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_reveal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundRevealModel _$RoundRevealModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoundRevealModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['correctOptionId', 'answers', 'answerAccess'],
      );
      final val = RoundRevealModel(
        correctOptionId: $checkedConvert(
          'correctOptionId',
          (v) => v as String?,
        ),
        answers: $checkedConvert(
          'answers',
          (v) => (v as List<dynamic>)
              .map((e) => RoundAnswerModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        answerAccess: $checkedConvert(
          'answerAccess',
          (v) => AnswerAccessModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
