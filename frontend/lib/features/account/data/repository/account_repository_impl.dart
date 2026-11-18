import 'dart:async';
import 'dart:developer' as developer;

import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/user_model.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/features/account/data/models/account_state_model.dart';
import 'package:skill_battles/features/account/data/models/activity_response_model.dart';
import 'package:skill_battles/features/account/data/models/limits_response_model.dart';
import 'package:skill_battles/features/account/data/models/season_history_page_model.dart';
import 'package:skill_battles/features/account/data/models/statistics_response_model.dart';
import 'package:skill_battles/features/account/data/models/update_profile_request_model.dart';
import 'package:skill_battles/features/account/data/models/update_profile_response_model.dart';
import 'package:skill_battles/features/account/data/sources/remote/account_remote.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_page_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

/// Remote only. Personal statistics, limits and entitlements are never
/// cached on the device (the API marks them `no-store`).
final class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({
    required this._remote,
    required this._realtime,
    required this._session,
  });

  final AccountRemote _remote;
  final RealtimeClient _realtime;
  final AuthSession _session;

  @override
  Future<Either<Failure, UserEntity>> getMe() async {
    try {
      final UserModel model = await _remote.getMe();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, UpdateProfileResultEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  ) async {
    try {
      final UpdateProfileResponseModel model = await _remote.updateMe(
        UpdateProfileRequestModel.fromEntity(params),
      );
      final UpdateProfileResultEntity result = model.toEntity();
      if (result.reauthenticationRequired) await _session.signOut();
      return Right(result);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, StatisticsEntity>> getStatistics() async {
    try {
      final StatisticsResponseModel model = await _remote.getStatistics();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, LimitsEntity>> getLimits() async {
    try {
      final LimitsResponseModel model = await _remote.getLimits();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, ActivityEntity>> getActivity() async {
    try {
      final ActivityResponseModel model = await _remote.getActivity();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, SeasonHistoryPageEntity>> getSeasonHistory(
    SeasonHistoryParamsEntity params,
  ) async {
    try {
      final SeasonHistoryPageModel model = await _remote.getSeasons(
        page: params.page,
        size: params.size,
        disciplineCode: params.disciplineCode,
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<AccountStateEntity> watchAccountChanges() => _realtime.events
      .where(
        (RealtimeEnvelope event) =>
            event.type == RealtimeEventType.accountChanged && event.resourceId == _session.userId,
      )
      .expand((RealtimeEnvelope event) {
        try {
          return <AccountStateEntity>[
            AccountStateModel.fromJson(event.data).toEntity(),
          ];
        } on CheckedFromJsonException catch (error) {
          developer.log(
            'Malformed ACCOUNT_CHANGED (${error.key})',
            name: 'account_repository',
          );
          return const <AccountStateEntity>[];
        }
      });
}
