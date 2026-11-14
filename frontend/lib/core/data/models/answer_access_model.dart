import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/answer_access_entity.dart';

part 'answer_access_model.g.dart';

/// What the caller may see of answers.
@JsonSerializable(checked: true, createToJson: false)
final class AnswerAccessModel {
  const AnswerAccessModel({
    required this.canViewCorrectAnswer,
    required this.canViewExplanation,
    required this.entitlementVersion,
  });

  factory AnswerAccessModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerAccessModelFromJson(json);

  @JsonKey(required: true)
  final bool canViewCorrectAnswer;

  @JsonKey(required: true)
  final bool canViewExplanation;

  @JsonKey(required: true)
  final int entitlementVersion;

  AnswerAccessEntity toEntity() => AnswerAccessEntity(
    canViewCorrectAnswer: canViewCorrectAnswer,
    canViewExplanation: canViewExplanation,
    entitlementVersion: entitlementVersion,
  );
}
