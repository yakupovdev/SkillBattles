import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/plan_code.dart';

/// Reuse the same [requestId] when retrying one purchase attempt, so the
/// server never opens a second Checkout.
final class StartCheckoutParamsEntity extends Equatable {
  const StartCheckoutParamsEntity({
    required this.planCode,
    required this.requestId,
  });

  final PlanCode planCode;
  final String requestId;

  @override
  List<Object?> get props => <Object?>[planCode, requestId];
}
