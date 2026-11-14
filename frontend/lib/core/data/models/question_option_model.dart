import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/question_option_entity.dart';

part 'question_option_model.g.dart';

/// Answer option.
@JsonSerializable(checked: true, createToJson: false)
final class QuestionOptionModel {
  const QuestionOptionModel({required this.id, required this.text});

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String text;

  QuestionOptionEntity toEntity() => QuestionOptionEntity(id: id, text: text);
}
