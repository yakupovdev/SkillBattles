import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/join_queue_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';

abstract interface class MatchmakingRepository {
  /// Checks the quota and reserves the activity; no attempt is consumed
  /// until the first question opens. May already be MATCHED.
  Future<Either<Failure, QueueEntryEntity>> joinQueue(
    JoinQueueParamsEntity params,
  );

  Future<Either<Failure, QueueEntryEntity>> getEntry(String entryId);

  /// Repeated cancellation of a cancelled/expired entry succeeds.
  Future<Either<Failure, Unit>> cancelEntry(String entryId);

  Stream<QueueEntryEntity> watchEntry(String entryId);
}
