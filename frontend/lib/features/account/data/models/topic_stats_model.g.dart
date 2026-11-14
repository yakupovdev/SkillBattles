// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicStatsModel _$TopicStatsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TopicStatsModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'topicCode',
      'topicName',
      'questionCount',
      'correctCount',
      'accuracyPercent',
      'avgAnswerTimeMs',
      'isWeakTopic',
    ],
  );
  final val = TopicStatsModel(
    topicCode: $checkedConvert('topicCode', (v) => v as String),
    topicName: $checkedConvert('topicName', (v) => v as String),
    questionCount: $checkedConvert('questionCount', (v) => (v as num).toInt()),
    correctCount: $checkedConvert('correctCount', (v) => (v as num).toInt()),
    accuracyPercent: $checkedConvert(
      'accuracyPercent',
      (v) => (v as num).toDouble(),
    ),
    avgAnswerTimeMs: $checkedConvert(
      'avgAnswerTimeMs',
      (v) => (v as num?)?.toInt(),
    ),
    isWeakTopic: $checkedConvert('isWeakTopic', (v) => v as bool),
  );
  return val;
});
