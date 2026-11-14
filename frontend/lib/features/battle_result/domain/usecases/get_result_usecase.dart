import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

final class GetResultUsecase
    implements
        Usecase<
          Future<Either<Failure, BattleResultEntity>>,
          ResultParamsEntity
        > {
  const GetResultUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Future<Either<Failure, BattleResultEntity>> call(ResultParamsEntity params) =>
      _repository.getResult(params.battleId);
}
