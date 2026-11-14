import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class IsSignedInUsecase implements Usecase<bool, NoParams> {
  const IsSignedInUsecase(this._repository);

  final AuthRepository _repository;

  @override
  bool call(NoParams params) => _repository.isSignedIn;
}
