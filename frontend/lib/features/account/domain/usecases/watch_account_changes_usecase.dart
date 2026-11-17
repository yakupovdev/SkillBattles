import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class WatchAccountChangesUsecase implements Usecase<Stream<AccountStateEntity>, NoParams> {
  const WatchAccountChangesUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Stream<AccountStateEntity> call(NoParams params) => _repository.watchAccountChanges();
}
