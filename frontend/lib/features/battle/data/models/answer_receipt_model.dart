import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';

part 'answer_receipt_model.g.dart';

/// Receipt of an accepted answer.
@JsonSerializable(checked: true, createToJson: false)
final class AnswerReceiptModel {
  const AnswerReceiptModel({
    required this.battleId,
    required this.roundId,
    required this.submissionId,
    required this.accepted,
    required this.acceptedAt,
  });

  factory AnswerReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerReceiptModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String roundId;

  @JsonKey(required: true)
  final String submissionId;

  @JsonKey(required: true)
  final bool accepted;

  @JsonKey(required: true)
  final DateTime acceptedAt;

  AnswerReceiptEntity toEntity() => AnswerReceiptEntity(
    roundId: roundId,
    submissionId: submissionId,
    acceptedAt: acceptedAt,
  );
}
