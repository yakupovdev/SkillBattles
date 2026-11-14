import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';

final class WatchQueueEntryUsecase
    implements Usecase<Stream<QueueEntryEntity>, QueueEntryParamsEntity> {
  const WatchQueueEntryUsecase(this._repository);

  final MatchmakingRepository _repository;

  @override
  Stream<QueueEntryEntity> call(QueueEntryParamsEntity params) =>
      _repository.watchEntry(params.entryId);
}
