import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class LogoutUsecase
    implements Usecase<Future<Either<Failure, Unit>>, NoParams> {
  const LogoutUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}
