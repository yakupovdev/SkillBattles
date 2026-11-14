import 'package:json_annotation/json_annotation.dart';

part 'accepted_response_model.g.dart';

/// Generic 202 body.
@JsonSerializable(checked: true, createToJson: false)
final class AcceptedResponseModel {
  const AcceptedResponseModel({required this.message});

  factory AcceptedResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AcceptedResponseModelFromJson(json);

  @JsonKey(required: true)
  final String message;
}
