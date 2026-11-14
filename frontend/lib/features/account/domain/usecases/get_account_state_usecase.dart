import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetAccountStateUsecase
    implements Usecase<Future<Either<Failure, AccountStateEntity>>, NoParams> {
  const GetAccountStateUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, AccountStateEntity>> call(NoParams params) =>
      _repository.getAccountState();
}
