import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetActivityUsecase
    implements Usecase<Future<Either<Failure, ActivityEntity>>, NoParams> {
  const GetActivityUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, ActivityEntity>> call(NoParams params) =>
      _repository.getActivity();
}
