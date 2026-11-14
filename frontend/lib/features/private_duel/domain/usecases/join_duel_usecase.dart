import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/join_duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';

/// Normalises the code (whitespace removed, upper case) and checks its
/// shape before joining.
final class JoinDuelUsecase
    implements
        Usecase<Future<Either<Failure, DuelEntity>>, JoinDuelParamsEntity> {
  const JoinDuelUsecase(this._repository);

  final PrivateDuelRepository _repository;

  static final RegExp _code = RegExp(r'^[A-Z0-9]{6}$');

  @override
  Future<Either<Failure, DuelEntity>> call(JoinDuelParamsEntity params) async {
    final String code = params.code.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!_code.hasMatch(code)) {
      return const Left(
        ValidationFailure(message: 'Enter the 6-character code.'),
      );
    }
    return _repository.joinDuel(code);
  }
}
