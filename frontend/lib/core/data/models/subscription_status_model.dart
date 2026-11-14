import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/subscription_status.dart';

/// Verified subscription status.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum SubscriptionStatusModel {
  none,
  incomplete,
  active,
  pastDue,
  canceled,
  unpaid,
  expired;

  SubscriptionStatus toEntity() => switch (this) {
    SubscriptionStatusModel.none => SubscriptionStatus.none,
    SubscriptionStatusModel.incomplete => SubscriptionStatus.incomplete,
    SubscriptionStatusModel.active => SubscriptionStatus.active,
    SubscriptionStatusModel.pastDue => SubscriptionStatus.pastDue,
    SubscriptionStatusModel.canceled => SubscriptionStatus.canceled,
    SubscriptionStatusModel.unpaid => SubscriptionStatus.unpaid,
    SubscriptionStatusModel.expired => SubscriptionStatus.expired,
  };
}
