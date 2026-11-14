import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';

final class GetDisciplinesUsecase
    implements
        Usecase<Future<Either<Failure, List<DisciplineEntity>>>, NoParams> {
  const GetDisciplinesUsecase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, List<DisciplineEntity>>> call(NoParams params) =>
      _repository.getDisciplines();
}
