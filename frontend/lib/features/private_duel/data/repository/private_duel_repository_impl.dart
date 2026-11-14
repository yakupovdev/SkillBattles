import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/discipline_request_model.dart';
import 'package:skill_battles/core/data/repository/realtime_decode.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/features/private_duel/data/models/duel_model.dart';
import 'package:skill_battles/features/private_duel/data/models/join_duel_request_model.dart';
import 'package:skill_battles/features/private_duel/data/sources/remote/private_duel_remote.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';

/// Remote and PRIVATE_DUEL_CHANGED events; nothing cached.
final class PrivateDuelRepositoryImpl implements PrivateDuelRepository {
  const PrivateDuelRepositoryImpl({
    required this._remote,
    required this._realtime,
  });

  final PrivateDuelRemote _remote;
  final RealtimeClient _realtime;

  @override
  Future<Either<Failure, DuelEntity>> createDuel(String disciplineCode) async {
    try {
      final DuelModel model = await _remote.createDuel(
        DisciplineRequestModel(
          disciplineCode: disciplineCode,
          format: BattleFormatModel.standard,
        ),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelEntity>> joinDuel(String code) async {
    try {
      final DuelModel model = await _remote.joinDuel(
        JoinDuelRequestModel(code: code),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, DuelEntity>> getDuel(String duelId) async {
    try {
      final DuelModel model = await _remote.getDuel(duelId);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelDuel(String duelId) async {
    try {
      await _remote.cancelDuel(duelId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<DuelEntity> watchDuel(String duelId) => decodeRealtime<DuelEntity>(
    _realtime.events,
    type: RealtimeEventType.privateDuelChanged,
    where: (RealtimeEnvelope event) =>
        event.resourceId == duelId || event.data['id'] == duelId,
    parse: (Map<String, dynamic> data) => DuelModel.fromJson(data).toEntity(),
  );
}
