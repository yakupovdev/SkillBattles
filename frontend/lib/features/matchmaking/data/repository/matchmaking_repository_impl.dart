import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/discipline_request_model.dart';
import 'package:skill_battles/core/data/repository/realtime_decode.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/features/matchmaking/data/models/queue_entry_model.dart';
import 'package:skill_battles/features/matchmaking/data/sources/remote/matchmaking_remote.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/join_queue_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/repository/matchmaking_repository.dart';

/// Remote and QUEUE_CHANGED events; nothing cached.
final class MatchmakingRepositoryImpl implements MatchmakingRepository {
  const MatchmakingRepositoryImpl({
    required this._remote,
    required this._realtime,
  });

  final MatchmakingRemote _remote;
  final RealtimeClient _realtime;

  @override
  Future<Either<Failure, QueueEntryEntity>> joinQueue(
    JoinQueueParamsEntity params,
  ) async {
    try {
      final QueueEntryModel model = await _remote.joinQueue(
        DisciplineRequestModel(
          disciplineCode: params.disciplineCode,
          format: BattleFormatModel.standard,
        ),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, QueueEntryEntity>> getEntry(String entryId) async {
    try {
      final QueueEntryModel model = await _remote.getEntry(entryId);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelEntry(String entryId) async {
    try {
      await _remote.cancelEntry(entryId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<QueueEntryEntity> watchEntry(String entryId) =>
      decodeRealtime<QueueEntryEntity>(
        _realtime.events,
        type: RealtimeEventType.queueChanged,
        where: (RealtimeEnvelope event) =>
            event.resourceId == entryId || event.data['id'] == entryId,
        parse: (Map<String, dynamic> data) =>
            QueueEntryModel.fromJson(data).toEntity(),
      );
}
