import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';

final class GetRanksUsecase
    implements Usecase<Future<Either<Failure, RankLadderEntity>>, NoParams> {
  const GetRanksUsecase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, RankLadderEntity>> call(NoParams params) =>
      _repository.getRanks();
}
