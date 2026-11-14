import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/history/domain/repository/history_repository.dart';

final class GetHistoryUsecase
    implements
        Usecase<
          Future<Either<Failure, HistoryPageEntity>>,
          HistoryParamsEntity
        > {
  const GetHistoryUsecase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, HistoryPageEntity>> call(HistoryParamsEntity params) =>
      _repository.getHistory(params);
}
