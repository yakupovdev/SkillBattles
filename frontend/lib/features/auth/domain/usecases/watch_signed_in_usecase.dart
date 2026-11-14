import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';

final class WatchSignedInUsecase implements Usecase<Stream<bool>, NoParams> {
  const WatchSignedInUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<bool> call(NoParams params) => _repository.watchSignedIn();
}
