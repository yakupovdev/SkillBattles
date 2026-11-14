import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

final class GetSubscriptionUsecase
    implements Usecase<Future<Either<Failure, SubscriptionEntity>>, NoParams> {
  const GetSubscriptionUsecase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionEntity>> call(NoParams params) =>
      _repository.getSubscription();
}
