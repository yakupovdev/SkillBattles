import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';

final class CancelQueueEntryUsecase
    implements Usecase<Future<Either<Failure, Unit>>, QueueEntryParamsEntity> {
  const CancelQueueEntryUsecase(this._repository);

  final MatchmakingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(QueueEntryParamsEntity params) =>
      _repository.cancelEntry(params.entryId);
}
