import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';

part 'answer_request_model.g.dart';

/// Body of POST /battles/{id}/answers.
@JsonSerializable(createFactory: false)
final class AnswerRequestModel {
  const AnswerRequestModel({
    required this.roundId,
    required this.optionId,
    required this.submissionId,
  });

  Map<String, dynamic> toJson() => _$AnswerRequestModelToJson(this);

  final String roundId;
  final String optionId;
  final String submissionId;

  factory AnswerRequestModel.fromEntity(SubmitAnswerParamsEntity params) =>
      AnswerRequestModel(
        roundId: params.roundId,
        optionId: params.optionId,
        submissionId: params.submissionId,
      );
}
