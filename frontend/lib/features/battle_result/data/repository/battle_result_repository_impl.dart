import 'package:skill_battles/core/data/models/battle_result_model.dart';
import 'package:skill_battles/core/data/repository/realtime_decode.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/features/battle_result/data/models/battle_review_model.dart';
import 'package:skill_battles/features/battle_result/data/models/rematch_model.dart';
import 'package:skill_battles/features/battle_result/data/models/report_request_model.dart';
import 'package:skill_battles/features/battle_result/data/models/report_response_model.dart';
import 'package:skill_battles/features/battle_result/data/sources/remote/battle_result_remote.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

/// Remote and REMATCH_CHANGED events. Reviews carry plan-gated answers, so
/// nothing is cached: an upgrade or downgrade is visible on the next read.
final class BattleResultRepositoryImpl implements BattleResultRepository {
  const BattleResultRepositoryImpl({
    required this._remote,
    required this._realtime,
    required this._session,
  });

  final BattleResultRemote _remote;
  final RealtimeClient _realtime;
  final AuthSession _session;

  String get _myUserId => _session.userId ?? '';

  @override
  Future<Either<Failure, BattleResultEntity>> getResult(String battleId) async {
    try {
      final BattleResultModel model = await _remote.getResult(battleId);
      return Right(model.toEntity(myUserId: _myUserId));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, BattleReviewEntity>> getReview(
    ReviewParamsEntity params,
  ) async {
    try {
      final BattleReviewModel model = await _remote.getReview(
        params.battleId,
        mistakesOnly: params.mistakesOnly ? true : null,
      );
      return Right(model.toEntity(myUserId: _myUserId));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RematchEntity?>> getRematch(String battleId) async {
    try {
      final RematchModel model = await _remote.getRematch(battleId);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      final Failure failure = mapExceptionToFailure(exception, stackTrace);
      // No consent yet is a normal state, not an error.
      if (failure.hasCode(ApiErrorCodes.rematchNotFound)) {
        return const Right(null);
      }
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, RematchEntity>> requestRematch(String battleId) async {
    try {
      final RematchModel model = await _remote.requestRematch(battleId);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelRematch(String battleId) async {
    try {
      await _remote.cancelRematch(battleId);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, ReportEntity>> reportRound(
    ReportParamsEntity params,
  ) async {
    try {
      final ReportResponseModel model = await _remote.reportRound(
        params.battleId,
        params.roundId,
        ReportRequestModel.fromEntity(params),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<RematchEntity> watchRematch(String battleId) =>
      decodeRealtime<RematchEntity>(
        _realtime.events,
        type: RealtimeEventType.rematchChanged,
        where: (RealtimeEnvelope event) =>
            event.resourceId == battleId ||
            event.data['sourceBattleId'] == battleId,
        parse: (Map<String, dynamic> data) =>
            RematchModel.fromJson(data).toEntity(),
      );

  @override
  Stream<RematchEntity> watchRematches() => decodeRealtime<RematchEntity>(
    _realtime.events,
    type: RealtimeEventType.rematchChanged,
    parse: (Map<String, dynamic> data) =>
        RematchModel.fromJson(data).toEntity(),
  );
}
