import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class DeclineDuelInvitationUsecase
    implements
        Usecase<
          Future<Either<Failure, DuelInvitationEntity>>,
          DuelInvitationParamsEntity
        > {
  const DeclineDuelInvitationUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, DuelInvitationEntity>> call(
    DuelInvitationParamsEntity params,
  ) => _repository.declineDuelInvitation(params.invitationId);
}
