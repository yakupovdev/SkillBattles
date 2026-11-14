import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';

abstract interface class PrivateDuelRepository {
  /// Unlimited for both plans.
  Future<Either<Failure, DuelEntity>> createDuel(String disciplineCode);

  /// Joins and creates the PRIVATE battle atomically.
  Future<Either<Failure, DuelEntity>> joinDuel(String code);

  Future<Either<Failure, DuelEntity>> getDuel(String duelId);

  Future<Either<Failure, Unit>> cancelDuel(String duelId);

  Stream<DuelEntity> watchDuel(String duelId);
}
