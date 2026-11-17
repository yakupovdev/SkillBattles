import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/subscription_model.dart';
import 'package:skill_battles/core/data/models/user_model.dart';
import 'package:skill_battles/features/account/data/models/limits_response_model.dart';
import 'package:skill_battles/features/account/data/models/streaks_model.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';

part 'account_state_model.g.dart';

/// Payload of the ACCOUNT_CHANGED event.
@JsonSerializable(checked: true, createToJson: false)
final class AccountStateModel {
  const AccountStateModel({
    required this.user,
    required this.subscription,
    required this.limits,
    required this.streaks,
  });

  factory AccountStateModel.fromJson(Map<String, dynamic> json) => _$AccountStateModelFromJson(json);

  @JsonKey(required: true)
  final UserModel user;

  @JsonKey(required: true)
  final SubscriptionModel subscription;

  @JsonKey(required: true)
  final LimitsResponseModel limits;

  @JsonKey(required: true)
  final StreaksModel streaks;

  AccountStateEntity toEntity() => AccountStateEntity(
    user: user.toEntity(),
    subscription: subscription.toEntity(),
    limits: limits.toEntity(),
    streaks: streaks.toEntity(),
  );
}
