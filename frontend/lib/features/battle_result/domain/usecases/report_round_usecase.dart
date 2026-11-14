import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';
import 'package:skill_battles/features/battle_result/domain/repository/battle_result_repository.dart';

/// "Other" needs a comment; comments are at most 1000 characters.
final class ReportRoundUsecase
    implements
        Usecase<Future<Either<Failure, ReportEntity>>, ReportParamsEntity> {
  const ReportRoundUsecase(this._repository);

  final BattleResultRepository _repository;

  @override
  Future<Either<Failure, ReportEntity>> call(ReportParamsEntity params) async {
    final String comment = params.comment?.trim() ?? '';
    if (params.reason == ReportReason.other && comment.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Describe the problem in a comment.'),
      );
    }
    if (comment.length > ReportParamsEntity.maxCommentLength) {
      return const Left(
        ValidationFailure(message: 'Keep the comment under 1000 characters.'),
      );
    }
    return _repository.reportRound(params);
  }
}
