import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/topic_stats_entity.dart';

part 'topic_stats_model.g.dart';

/// Per-topic accuracy (Pro only).
@JsonSerializable(checked: true, createToJson: false)
final class TopicStatsModel {
  const TopicStatsModel({
    required this.topicCode,
    required this.topicName,
    required this.questionCount,
    required this.correctCount,
    required this.accuracyPercent,
    required this.avgAnswerTimeMs,
    required this.isWeakTopic,
  });

  factory TopicStatsModel.fromJson(Map<String, dynamic> json) => _$TopicStatsModelFromJson(json);

  @JsonKey(required: true)
  final String topicCode;

  @JsonKey(required: true)
  final String topicName;

  @JsonKey(required: true)
  final int questionCount;

  @JsonKey(required: true)
  final int correctCount;

  @JsonKey(required: true)
  final double accuracyPercent;

  @JsonKey(required: true)
  final int? avgAnswerTimeMs;

  @JsonKey(required: true)
  final bool isWeakTopic;

  TopicStatsEntity toEntity() {
    final int? avgMs = avgAnswerTimeMs;
    return TopicStatsEntity(
      topicCode: topicCode,
      topicName: topicName,
      questionCount: questionCount,
      correctCount: correctCount,
      accuracyPercent: accuracyPercent,
      avgAnswerTime: avgMs == null ? null : Duration(milliseconds: avgMs),
      isWeakTopic: isWeakTopic,
    );
  }
}
