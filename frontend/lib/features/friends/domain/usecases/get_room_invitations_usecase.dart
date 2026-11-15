import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/room_invitations_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class GetRoomInvitationsUsecase
    implements
        Usecase<
          Future<Either<Failure, DuelInvitationsSnapshotEntity>>,
          RoomInvitationsParamsEntity
        > {
  const GetRoomInvitationsUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> call(
    RoomInvitationsParamsEntity params,
  ) => _repository.getRoomInvitations(params.duelId);
}
