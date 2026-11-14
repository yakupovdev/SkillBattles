import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class LoginUsecase
    implements Usecase<Future<Either<Failure, UserEntity>>, LoginParamsEntity> {
  const LoginUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParamsEntity params) =>
      _repository.login(params);
}
