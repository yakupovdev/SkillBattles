import 'package:json_annotation/json_annotation.dart';

part 'field_error_model.g.dart';

/// Single request validation error.
@JsonSerializable(checked: true, createToJson: false)
final class FieldErrorModel {
  const FieldErrorModel({required this.field, required this.message});

  factory FieldErrorModel.fromJson(Map<String, dynamic> json) =>
      _$FieldErrorModelFromJson(json);

  @JsonKey(required: true)
  final String field;

  @JsonKey(required: true)
  final String message;
}
