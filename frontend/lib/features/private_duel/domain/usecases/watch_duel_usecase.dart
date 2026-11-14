import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';

final class WatchDuelUsecase
    implements Usecase<Stream<DuelEntity>, DuelParamsEntity> {
  const WatchDuelUsecase(this._repository);

  final PrivateDuelRepository _repository;

  @override
  Stream<DuelEntity> call(DuelParamsEntity params) =>
      _repository.watchDuel(params.duelId);
}
