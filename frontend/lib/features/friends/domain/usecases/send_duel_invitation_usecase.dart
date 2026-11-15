import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class SendDuelInvitationUsecase
    implements
        Usecase<
          Future<Either<Failure, DuelInvitationEntity>>,
          SendDuelInvitationParamsEntity
        > {
  const SendDuelInvitationUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, DuelInvitationEntity>> call(
    SendDuelInvitationParamsEntity params,
  ) => _repository.sendDuelInvitation(params);
}
