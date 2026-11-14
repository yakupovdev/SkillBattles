import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_page_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_params_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetSeasonHistoryUsecase
    implements
        Usecase<
          Future<Either<Failure, SeasonHistoryPageEntity>>,
          SeasonHistoryParamsEntity
        > {
  const GetSeasonHistoryUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, SeasonHistoryPageEntity>> call(
    SeasonHistoryParamsEntity params,
  ) => _repository.getSeasonHistory(params);
}
