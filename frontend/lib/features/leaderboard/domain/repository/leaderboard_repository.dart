import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';

abstract interface class LeaderboardRepository {
  Future<Either<Failure, LeaderboardEntity>> getLeaderboard(
    String disciplineCode,
  );
}
