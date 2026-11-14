import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/leaderboard/data/models/leaderboard_model.dart';
import 'package:skill_battles/features/leaderboard/data/sources/remote/leaderboard_remote.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/repository/leaderboard_repository.dart';

/// Remote only.
final class LeaderboardRepositoryImpl implements LeaderboardRepository {
  const LeaderboardRepositoryImpl({required this._remote});

  final LeaderboardRemote _remote;

  @override
  Future<Either<Failure, LeaderboardEntity>> getLeaderboard(
    String disciplineCode,
  ) async {
    try {
      final LeaderboardModel model = await _remote.getLeaderboard(
        disciplineCode,
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }
}
