import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

/// Every rematch change of the signed-in user, whatever the source battle.
final class WatchRematchesUsecase
    implements Usecase<Stream<RematchEntity>, NoParams> {
  const WatchRematchesUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Stream<RematchEntity> call(NoParams params) => _repository.watchRematches();
}
