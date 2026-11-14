import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/join_queue_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';

final class JoinQueueUsecase
    implements
        Usecase<
          Future<Either<Failure, QueueEntryEntity>>,
          JoinQueueParamsEntity
        > {
  const JoinQueueUsecase(this._repository);

  final MatchmakingRepository _repository;

  @override
  Future<Either<Failure, QueueEntryEntity>> call(
    JoinQueueParamsEntity params,
  ) => _repository.joinQueue(params);
}
