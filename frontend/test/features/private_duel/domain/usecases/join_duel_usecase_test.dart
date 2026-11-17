import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';
import 'package:skill_battles/features/private_duel/domain/entity/join_duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/join_duel_usecase.dart';

final class _Repository implements PrivateDuelRepository {
  final List<String> joined = <String>[];

  @override
  Future<Either<Failure, DuelEntity>> joinDuel(String code) async {
    joined.add(code);
    return Right(
      DuelEntity(
        id: 'd',
        code: code,
        disciplineCode: 'SAT_MATH',
        status: DuelStatus.matched,
        host: const PublicPlayerEntity(id: 'h', nickname: 'h', isPro: false),
        guest: null,
        expiresAt: DateTime.utc(2026),
        battleId: 'b',
        version: 2,
      ),
    );
  }

  @override
  Future<Either<Failure, DuelEntity>> createDuel(String disciplineCode) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, DuelEntity>> getDuel(String duelId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> cancelDuel(String duelId) =>
      throw UnimplementedError();

  @override
  Stream<DuelEntity> watchDuel(String duelId) =>
      const Stream<DuelEntity>.empty();
}

void main() {
  test('the code is normalised before joining', () async {
    final _Repository repository = _Repository();

    await JoinDuelUsecase(repository)(
      const JoinDuelParamsEntity(code: ' k7p 9xz '),
    );

    expect(repository.joined, <String>['K7P9XZ']);
  });

  test('a malformed code is rejected without a request', () async {
    final _Repository repository = _Repository();

    final Either<Failure, DuelEntity> result = await JoinDuelUsecase(
      repository,
    )(const JoinDuelParamsEntity(code: 'AB1'));

    expect(result.getLeft(), isA<ValidationFailure>());
    expect(repository.joined, isEmpty);
  });
}
