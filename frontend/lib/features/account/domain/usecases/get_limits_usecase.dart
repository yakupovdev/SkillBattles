import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetLimitsUsecase implements Usecase<Future<Either<Failure, LimitsEntity>>, NoParams> {
  const GetLimitsUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, LimitsEntity>> call(NoParams params) => _repository.getLimits();
}
