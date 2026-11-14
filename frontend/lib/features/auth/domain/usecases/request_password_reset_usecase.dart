import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class RequestPasswordResetUsecase
    implements
        Usecase<
          Future<Either<Failure, String>>,
          PasswordResetRequestParamsEntity
        > {
  const RequestPasswordResetUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, String>> call(
    PasswordResetRequestParamsEntity params,
  ) => _repository.requestPasswordReset(params);
}
