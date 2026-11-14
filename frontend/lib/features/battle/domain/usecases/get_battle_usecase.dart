import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

final class GetBattleUsecase
    implements
        Usecase<
          Future<Either<Failure, BattleSnapshotEntity>>,
          BattleParamsEntity
        > {
  const GetBattleUsecase(this._repository);

  final BattleRepository _repository;

  @override
  Future<Either<Failure, BattleSnapshotEntity>> call(
    BattleParamsEntity params,
  ) => _repository.getBattle(params.battleId);
}
