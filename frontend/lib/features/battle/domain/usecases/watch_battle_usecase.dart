import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

final class WatchBattleUsecase
    implements Usecase<Stream<BattleSnapshotEntity>, BattleParamsEntity> {
  const WatchBattleUsecase(this._repository);

  final BattleRepository _repository;

  @override
  Stream<BattleSnapshotEntity> call(BattleParamsEntity params) =>
      _repository.watchBattle(params.battleId);
}
