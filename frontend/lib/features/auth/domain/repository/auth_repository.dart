import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';

abstract interface class AuthRepository {
  /// Signs the new account in on success.
  Future<Either<Failure, UserEntity>> register(RegisterParamsEntity params);

  Future<Either<Failure, UserEntity>> login(LoginParamsEntity params);

  /// Revokes the refresh token, then forgets the pair locally (also when
  /// the server is unreachable).
  Future<Either<Failure, Unit>> logout();

  /// Generic message; never reveals whether the account exists.
  Future<Either<Failure, String>> requestPasswordReset(
    PasswordResetRequestParamsEntity params,
  );

  Future<Either<Failure, Unit>> confirmPasswordReset(
    PasswordResetConfirmParamsEntity params,
  );

  /// Whether an account is signed in; emits on every change.
  Stream<bool> watchSignedIn();

  bool get isSignedIn;
}
