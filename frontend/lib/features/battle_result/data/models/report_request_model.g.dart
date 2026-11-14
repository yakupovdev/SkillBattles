// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ReportRequestModelToJson(ReportRequestModel instance) =>
    <String, dynamic>{
      'reason': _$ReportReasonModelEnumMap[instance.reason]!,
      'comment': ?instance.comment,
    };

const _$ReportReasonModelEnumMap = {
  ReportReasonModel.incorrectAnswer: 'INCORRECT_ANSWER',
  ReportReasonModel.unclearQuestion: 'UNCLEAR_QUESTION',
  ReportReasonModel.typo: 'TYPO',
  ReportReasonModel.other: 'OTHER',
};
