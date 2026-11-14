import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/field_error_model.dart';
import 'package:skill_battles/core/utils/error/failure.dart';

part 'error_response_model.g.dart';

/// Error body shared by every non-2xx response.
@JsonSerializable(checked: true, createToJson: false)
final class ErrorResponseModel {
  const ErrorResponseModel({
    required this.code,
    required this.message,
    required this.fieldErrors,
    required this.resetsAt,
  });

  factory ErrorResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseModelFromJson(json);

  @JsonKey(required: true)
  final String code;

  @JsonKey(required: true)
  final String message;

  @JsonKey(required: true)
  final List<FieldErrorModel> fieldErrors;

  @JsonKey(required: true)
  final DateTime? resetsAt;

  /// An error delivered inside a resource (asynchronous cancellation).
  ApiFailure toFailure({int statusCode = 0}) => ApiFailure(
    statusCode: statusCode,
    errorCode: code,
    message: message,
    fieldErrors: <String, String>{
      for (final FieldErrorModel field in fieldErrors)
        field.field: field.message,
    },
    resetsAt: resetsAt,
  );
}
