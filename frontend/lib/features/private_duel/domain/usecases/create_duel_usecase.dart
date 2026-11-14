import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/create_duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';

final class CreateDuelUsecase
    implements
        Usecase<Future<Either<Failure, DuelEntity>>, CreateDuelParamsEntity> {
  const CreateDuelUsecase(this._repository);

  final PrivateDuelRepository _repository;

  @override
  Future<Either<Failure, DuelEntity>> call(CreateDuelParamsEntity params) =>
      _repository.createDuel(params.disciplineCode);
}
