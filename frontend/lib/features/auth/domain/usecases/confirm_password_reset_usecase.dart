import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class ConfirmPasswordResetUsecase
    implements
        Usecase<
          Future<Either<Failure, Unit>>,
          PasswordResetConfirmParamsEntity
        > {
  const ConfirmPasswordResetUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(PasswordResetConfirmParamsEntity params) =>
      _repository.confirmPasswordReset(params);
}
