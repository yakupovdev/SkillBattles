import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

final class WatchRematchUsecase
    implements Usecase<Stream<RematchEntity>, ResultParamsEntity> {
  const WatchRematchUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Stream<RematchEntity> call(ResultParamsEntity params) =>
      _repository.watchRematch(params.battleId);
}
