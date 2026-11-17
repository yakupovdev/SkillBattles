import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

/// Profile, verified subscription and limits read together, in parallel.
/// On failure the first one in that order is returned.
final class GetAccountStateUsecase implements Usecase<Future<Either<Failure, AccountStateEntity>>, NoParams> {
  const GetAccountStateUsecase(this._account, this._subscription);

  final AccountRepository _account;
  final SubscriptionRepository _subscription;

  @override
  Future<Either<Failure, AccountStateEntity>> call(NoParams params) async {
    final (
      Either<Failure, UserEntity> user,
      Either<Failure, SubscriptionEntity> subscription,
      Either<Failure, LimitsEntity> limits,
    ) = await (
      _account.getMe(),
      _subscription.getSubscription(),
      _account.getLimits(),
    ).wait;

    return switch ((user, subscription, limits)) {
      (
        Right(value: final UserEntity user),
        Right(value: final SubscriptionEntity subscription),
        Right(value: final LimitsEntity limits),
      ) =>
        Right(
          AccountStateEntity(
            user: user,
            subscription: subscription,
            limits: limits,
          ),
        ),
      _ => Left(
        user.getLeft() ?? subscription.getLeft() ?? limits.getLeft()!,
      ),
    };
  }
}
