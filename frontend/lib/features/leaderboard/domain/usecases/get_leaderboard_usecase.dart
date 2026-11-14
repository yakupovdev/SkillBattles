import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_params_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/repository/leaderboard_repository.dart';

final class GetLeaderboardUsecase
    implements
        Usecase<
          Future<Either<Failure, LeaderboardEntity>>,
          LeaderboardParamsEntity
        > {
  const GetLeaderboardUsecase(this._repository);

  final LeaderboardRepository _repository;

  @override
  Future<Either<Failure, LeaderboardEntity>> call(
    LeaderboardParamsEntity params,
  ) => _repository.getLeaderboard(params.disciplineCode);
}
