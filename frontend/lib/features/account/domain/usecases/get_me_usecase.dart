import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetMeUsecase
    implements Usecase<Future<Either<Failure, UserEntity>>, NoParams> {
  const GetMeUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.getMe();
}
