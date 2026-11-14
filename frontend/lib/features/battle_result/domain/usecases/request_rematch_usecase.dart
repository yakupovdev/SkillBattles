import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

final class RequestRematchUsecase
    implements
        Usecase<Future<Either<Failure, RematchEntity>>, ResultParamsEntity> {
  const RequestRematchUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Future<Either<Failure, RematchEntity>> call(ResultParamsEntity params) =>
      _repository.requestRematch(params.battleId);
}
