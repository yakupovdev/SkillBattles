// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_round_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewRoundModel _$ReviewRoundModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewRoundModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'roundId',
          'number',
          'isOvertimeRound',
          'completed',
          'question',
          'answers',
        ],
      );
      final val = ReviewRoundModel(
        roundId: $checkedConvert('roundId', (v) => v as String),
        number: $checkedConvert('number', (v) => (v as num).toInt()),
        isOvertimeRound: $checkedConvert('isOvertimeRound', (v) => v as bool),
        completed: $checkedConvert('completed', (v) => v as bool),
        question: $checkedConvert(
          'question',
          (v) => ReviewQuestionModel.fromJson(v as Map<String, dynamic>),
        ),
        answers: $checkedConvert(
          'answers',
          (v) => (v as List<dynamic>)
              .map((e) => RoundAnswerModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });
