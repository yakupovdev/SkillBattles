import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';

abstract interface class CatalogRepository {
  /// Active disciplines only.
  Future<Either<Failure, List<DisciplineEntity>>> getDisciplines();

  Future<Either<Failure, RankLadderEntity>> getRanks();

  Future<Either<Failure, SeasonEntity>> getCurrentSeason();
}
