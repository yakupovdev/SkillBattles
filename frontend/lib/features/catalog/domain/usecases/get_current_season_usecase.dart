import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';

final class GetCurrentSeasonUsecase
    implements Usecase<Future<Either<Failure, SeasonEntity>>, NoParams> {
  const GetCurrentSeasonUsecase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, SeasonEntity>> call(NoParams params) =>
      _repository.getCurrentSeason();
}
