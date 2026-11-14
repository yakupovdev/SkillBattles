import 'package:json_annotation/json_annotation.dart';

part 'portal_model.g.dart';

/// Stripe customer portal session.
@JsonSerializable(checked: true, createToJson: false)
final class PortalModel {
  const PortalModel({required this.url});

  factory PortalModel.fromJson(Map<String, dynamic> json) =>
      _$PortalModelFromJson(json);

  @JsonKey(required: true)
  final String url;
}
