import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/subscription/domain/entity/checkout_entity.dart';

part 'checkout_model.g.dart';

/// Stripe-hosted checkout session.
@JsonSerializable(checked: true, createToJson: false)
final class CheckoutModel {
  const CheckoutModel({
    required this.checkoutSessionId,
    required this.url,
    required this.expiresAt,
  });

  factory CheckoutModel.fromJson(Map<String, dynamic> json) =>
      _$CheckoutModelFromJson(json);

  @JsonKey(required: true)
  final String checkoutSessionId;

  @JsonKey(required: true)
  final String url;

  @JsonKey(required: true)
  final DateTime expiresAt;

  CheckoutEntity toEntity() => CheckoutEntity(
    sessionId: checkoutSessionId,
    url: url,
    expiresAt: expiresAt,
  );
}
