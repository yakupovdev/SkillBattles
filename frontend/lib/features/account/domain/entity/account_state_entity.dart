import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';

/// Everything the shell needs about the account. [streaks] is `null` on the
/// first load (it comes with statistics) and set by ACCOUNT_CHANGED.
final class AccountStateEntity extends Equatable {
  const AccountStateEntity({
    required this.user,
    required this.subscription,
    required this.limits,
    this.streaks,
  });

  final UserEntity user;
  final SubscriptionEntity subscription;
  final LimitsEntity limits;
  final StreaksEntity? streaks;

  @override
  List<Object?> get props => <Object?>[user, subscription, limits, streaks];
}
