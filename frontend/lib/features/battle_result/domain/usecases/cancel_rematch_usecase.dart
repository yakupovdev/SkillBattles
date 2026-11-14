import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

final class CancelRematchUsecase
    implements Usecase<Future<Either<Failure, Unit>>, ResultParamsEntity> {
  const CancelRematchUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ResultParamsEntity params) =>
      _repository.cancelRematch(params.battleId);
}
