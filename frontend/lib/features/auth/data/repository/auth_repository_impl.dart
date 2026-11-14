import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/features/auth/data/models/accepted_response_model.dart';
import 'package:skill_battles/features/auth/data/models/auth_response_model.dart';
import 'package:skill_battles/features/auth/data/models/login_request_model.dart';
import 'package:skill_battles/features/auth/data/models/password_reset_confirm_request_model.dart';
import 'package:skill_battles/features/auth/data/models/password_reset_request_model.dart';
import 'package:skill_battles/features/auth/data/models/register_request_model.dart';
import 'package:skill_battles/features/auth/data/sources/remote/auth_remote.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

/// Remote only. A successful sign-up/log-in stores the pair in
/// [AuthSession]; nothing is cached.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._remote, required this._session});

  final AuthRemote _remote;
  final AuthSession _session;

  @override
  Future<Either<Failure, UserEntity>> register(
    RegisterParamsEntity params,
  ) async {
    try {
      final AuthResponseModel model = await _remote.register(
        RegisterRequestModel.fromEntity(params),
      );
      await _session.signIn(model.toSessionTokens());
      return Right(model.user.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(LoginParamsEntity params) async {
    try {
      final AuthResponseModel model = await _remote.login(
        LoginRequestModel.fromEntity(params),
      );
      await _session.signIn(model.toSessionTokens());
      return Right(model.user.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final String? refreshToken = _session.isSignedIn
        ? await _session.currentRefreshToken()
        : null;
    try {
      if (refreshToken != null) await _remote.logout(refreshToken);
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      // Already revoked or unreachable: the local sign-out still happens.
      final Failure failure = mapExceptionToFailure(exception, stackTrace);
      return failure is ApiFailure ? const Right(unit) : Left(failure);
    } finally {
      await _session.signOut();
    }
  }

  @override
  Future<Either<Failure, String>> requestPasswordReset(
    PasswordResetRequestParamsEntity params,
  ) async {
    try {
      final AcceptedResponseModel model = await _remote.requestPasswordReset(
        PasswordResetRequestModel.fromEntity(params),
      );
      return Right(model.message);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmPasswordReset(
    PasswordResetConfirmParamsEntity params,
  ) async {
    try {
      await _remote.confirmPasswordReset(
        PasswordResetConfirmRequestModel.fromEntity(params),
      );
      // Every refresh token is revoked: a session on this device is stale.
      await _session.signOut();
      return const Right(unit);
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Stream<bool> watchSignedIn() =>
      _session.changes.map((SessionTokens? tokens) => tokens != null);

  @override
  bool get isSignedIn => _session.isSignedIn;
}
