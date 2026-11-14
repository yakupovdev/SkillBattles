import 'package:equatable/equatable.dart';

/// Pro topic analytics over the whole history.
final class TopicStatsEntity extends Equatable {
  const TopicStatsEntity({
    required this.topicCode,
    required this.topicName,
    required this.questionCount,
    required this.correctCount,
    required this.accuracyPercent,
    required this.avgAnswerTime,
    required this.isWeakTopic,
  });

  final String topicCode;
  final String topicName;
  final int questionCount;
  final int correctCount;
  final double accuracyPercent;
  final Duration? avgAnswerTime;

  /// Accuracy below 65% over at least five questions.
  final bool isWeakTopic;

  @override
  List<Object?> get props => <Object?>[
    topicCode,
    topicName,
    questionCount,
    correctCount,
    accuracyPercent,
    avgAnswerTime,
    isWeakTopic,
  ];
}
