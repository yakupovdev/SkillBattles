import 'package:json_annotation/json_annotation.dart';

part 'readiness_request_model.g.dart';

/// Body of POST /battles/{id}/readiness; only true is allowed.
@JsonSerializable(createFactory: false)
final class ReadinessRequestModel {
  const ReadinessRequestModel({required this.ready});

  Map<String, dynamic> toJson() => _$ReadinessRequestModelToJson(this);

  final bool ready;
}
