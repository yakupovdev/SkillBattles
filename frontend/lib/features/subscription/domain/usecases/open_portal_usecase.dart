import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/subscription/domain/repository/subscription_repository.dart';

final class OpenPortalUsecase
    implements Usecase<Future<Either<Failure, String>>, NoParams> {
  const OpenPortalUsecase(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) =>
      _repository.openPortal();
}
