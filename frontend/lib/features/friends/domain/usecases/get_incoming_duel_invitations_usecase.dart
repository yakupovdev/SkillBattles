import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class GetIncomingDuelInvitationsUsecase
    implements
        Usecase<
          Future<Either<Failure, DuelInvitationsSnapshotEntity>>,
          NoParams
        > {
  const GetIncomingDuelInvitationsUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> call(
    NoParams params,
  ) => _repository.getIncomingDuelInvitations();
}
