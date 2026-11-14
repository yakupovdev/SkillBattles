import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/plan_code_model.dart';

part 'checkout_request_model.g.dart';

/// Body of POST /subscriptions/checkout.
@JsonSerializable(createFactory: false)
final class CheckoutRequestModel {
  const CheckoutRequestModel({required this.planCode, required this.requestId});

  Map<String, dynamic> toJson() => _$CheckoutRequestModelToJson(this);

  final PlanCodeModel planCode;
  final String requestId;
}
