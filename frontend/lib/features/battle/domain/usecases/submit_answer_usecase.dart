import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

final class SubmitAnswerUsecase
    implements
        Usecase<
          Future<Either<Failure, AnswerReceiptEntity>>,
          SubmitAnswerParamsEntity
        > {
  const SubmitAnswerUsecase(this._repository);

  final BattleRepository _repository;

  @override
  Future<Either<Failure, AnswerReceiptEntity>> call(
    SubmitAnswerParamsEntity params,
  ) => _repository.submitAnswer(params);
}
