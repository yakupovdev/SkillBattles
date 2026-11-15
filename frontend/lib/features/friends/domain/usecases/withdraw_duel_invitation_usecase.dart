import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class WithdrawDuelInvitationUsecase
    implements
        Usecase<Future<Either<Failure, Unit>>, DuelInvitationParamsEntity> {
  const WithdrawDuelInvitationUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DuelInvitationParamsEntity params) =>
      _repository.withdrawDuelInvitation(params.invitationId);
}
