import 'package:skill_battles/core/data/models/season_model.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/data/models/battle_mode_model.dart';
import 'package:skill_battles/features/catalog/data/models/rank_tier_model.dart';
import 'package:skill_battles/features/catalog/data/sources/remote/catalog_remote.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/repository/catalog_repository.dart';

/// Remote only: the catalogue is configuration and availability can change
/// at any time, so every screen reads it fresh.
final class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({required this._remote});

  final CatalogRemote _remote;

  @override
  Future<Either<Failure, List<DisciplineEntity>>> getDisciplines() async {
    try {
      final List<BattleModeModel> models = await _remote.getBattleModes();
      return Right(
        models
            .where((BattleModeModel model) => model.active)
            .map((BattleModeModel model) => model.toEntity())
            .toList(growable: false),
      );
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RankLadderEntity>> getRanks() async {
    try {
      final List<RankTierModel> models = await _remote.getRanks();
      final List<RankTierModel> sorted = <RankTierModel>[...models]
        ..sort(
          (RankTierModel a, RankTierModel b) =>
              a.floorRating.compareTo(b.floorRating),
        );
      return Right(
        RankLadderEntity(
          tiers: sorted
              .map((RankTierModel model) => model.toEntity())
              .toList(growable: false),
        ),
      );
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }

  @override
  Future<Either<Failure, SeasonEntity>> getCurrentSeason() async {
    try {
      final SeasonModel model = await _remote.getCurrentSeason();
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }
}
