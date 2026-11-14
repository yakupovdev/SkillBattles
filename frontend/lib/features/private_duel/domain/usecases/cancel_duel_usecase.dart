import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';

final class CancelDuelUsecase
    implements Usecase<Future<Either<Failure, Unit>>, DuelParamsEntity> {
  const CancelDuelUsecase(this._repository);

  final PrivateDuelRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DuelParamsEntity params) =>
      _repository.cancelDuel(params.duelId);
}
