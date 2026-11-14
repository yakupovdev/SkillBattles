import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';

final class GetQueueEntryUsecase
    implements
        Usecase<
          Future<Either<Failure, QueueEntryEntity>>,
          QueueEntryParamsEntity
        > {
  const GetQueueEntryUsecase(this._repository);

  final MatchmakingRepository _repository;

  @override
  Future<Either<Failure, QueueEntryEntity>> call(
    QueueEntryParamsEntity params,
  ) => _repository.getEntry(params.entryId);
}
