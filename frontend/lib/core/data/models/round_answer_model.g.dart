// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_answer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundAnswerModel _$RoundAnswerModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoundAnswerModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'userId',
          'selectedOptionId',
          'correct',
          'elapsedMs',
          'basePoints',
          'speedBonus',
          'streakBonus',
          'tieBreakPoints',
          'points',
          'timedOut',
        ],
      );
      final val = RoundAnswerModel(
        userId: $checkedConvert('userId', (v) => v as String),
        selectedOptionId: $checkedConvert(
          'selectedOptionId',
          (v) => v as String?,
        ),
        correct: $checkedConvert('correct', (v) => v as bool),
        elapsedMs: $checkedConvert('elapsedMs', (v) => (v as num?)?.toInt()),
        basePoints: $checkedConvert('basePoints', (v) => (v as num).toInt()),
        speedBonus: $checkedConvert('speedBonus', (v) => (v as num).toInt()),
        streakBonus: $checkedConvert('streakBonus', (v) => (v as num).toInt()),
        tieBreakPoints: $checkedConvert(
          'tieBreakPoints',
          (v) => (v as num).toInt(),
        ),
        points: $checkedConvert('points', (v) => (v as num).toInt()),
        timedOut: $checkedConvert('timedOut', (v) => v as bool),
      );
      return val;
    });
