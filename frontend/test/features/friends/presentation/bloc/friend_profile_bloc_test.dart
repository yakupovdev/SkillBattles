import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_profile_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friend_profile_bloc/friend_profile_bloc.dart';

import '../../../../helpers/friends_fakes.dart';
import '../../../../helpers/notification_fakes.dart';

Future<void> _settle() async {
  for (int i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late ScriptedFriendsRepository repo;
  late FakeConnectionRepository connection;
  late FriendProfileBloc bloc;

  setUp(() {
    repo = ScriptedFriendsRepository();
    connection = FakeConnectionRepository();
    bloc = FriendProfileBloc(
      getFriendProfile: GetFriendProfileUsecase(repo),
      removeFriend: RemoveFriendUsecase(repo),
      watchFriendshipChanges: WatchFriendshipChangesUsecase(repo),
      watchConnection: WatchConnectionUsecase(connection),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.dispose();
    await connection.changes.close();
  });

  Future<void> start() async {
    bloc.add(
      FriendProfileStarted(friendId: friendAnna.id, relationshipId: 'rel-1'),
    );
    await _settle();
  }

  group('FriendProfileBloc', () {
    test('FRIEND_NOT_FOUND clears previously loaded profile', () async {
      await start();
      expect(bloc.stateValue.profile, profileOf(friendAnna));
      repo.onGetFriendProfile = (_) async =>
          failed(apiFailure(ApiErrorCodes.friendNotFound, status: 404));

      bloc.add(const FriendProfileRefreshRequested());
      await _settle();

      expect(bloc.stateValue.isNoLongerFriends, isTrue);
      expect(bloc.stateValue.profile, isNull);
      expect(bloc.stateValue.failure, isNull);
    });

    test('REMOVED for same relationship clears profile without read', () async {
      await start();
      repo.friendships.add(
        relationship('rel-1', status: RelationshipStatus.removed, version: 2),
      );
      await _settle();

      expect(bloc.stateValue.isNoLongerFriends, isTrue);
      expect(bloc.stateValue.profile, isNull);
      expect(repo.profileCalls, <String>[friendAnna.id]);
    });

    test('REMOVED for old relationship refetches current profile', () async {
      await start();
      repo.friendships.add(
        relationship('old-rel', status: RelationshipStatus.removed, version: 9),
      );
      await _settle();

      expect(repo.profileCalls, <String>[friendAnna.id, friendAnna.id]);
      expect(bloc.stateValue.isNoLongerFriends, isFalse);
      expect(bloc.stateValue.profile, profileOf(friendAnna));
    });

    test('REMOVED for another friend leaves profile unchanged', () async {
      await start();
      repo.friendships.add(
        relationship(
          'other-rel',
          status: RelationshipStatus.removed,
          other: friendBoris,
          version: 2,
        ),
      );
      await _settle();

      expect(repo.profileCalls, hasLength(1));
      expect(bloc.stateValue.isNoLongerFriends, isFalse);
    });

    test(
      'failed refresh keeps profile and successful retry clears error',
      () async {
        await start();
        repo.onGetFriendProfile = (_) async => failed(const TimeoutFailure());
        bloc.add(const FriendProfileRefreshRequested());
        await _settle();
        expect(bloc.stateValue.loadStatus, LoadStatus.failure);
        expect(bloc.stateValue.profile, profileOf(friendAnna));
        expect(bloc.stateValue.failure, const TimeoutFailure());

        repo.onGetFriendProfile = (_) async => ok(profileOf(friendAnna));
        bloc.add(const FriendProfileRefreshRequested());
        await _settle();
        expect(bloc.stateValue.loadStatus, LoadStatus.success);
        expect(bloc.stateValue.failure, isNull);
      },
    );

    test(
      'late read cannot restore profile after matching REMOVED push',
      () async {
        await start();
        final Completer<Either<Failure, FriendProfileEntity>> answer =
            Completer<Either<Failure, FriendProfileEntity>>();
        repo.onGetFriendProfile = (_) => answer.future;
        bloc.add(const FriendProfileRefreshRequested());
        await _settle();
        repo.friendships.add(
          relationship('rel-1', status: RelationshipStatus.removed, version: 2),
        );
        await _settle();
        answer.complete(ok(profileOf(friendAnna)));
        await _settle();

        expect(bloc.stateValue.isNoLongerFriends, isTrue);
        expect(bloc.stateValue.profile, isNull);
      },
    );

    test('newer refresh wins when older answer completes last', () async {
      await start();
      final Completer<Either<Failure, FriendProfileEntity>> older =
          Completer<Either<Failure, FriendProfileEntity>>();
      repo.onGetFriendProfile = (_) => older.future;
      bloc.add(const FriendProfileRefreshRequested());
      await _settle();
      repo.onGetFriendProfile = (_) async => ok(profileOf(friendBoris));
      bloc.add(const FriendProfileRefreshRequested());
      await _settle();
      older.complete(ok(profileOf(friendAnna)));
      await _settle();

      expect(bloc.stateValue.profile, profileOf(friendBoris));
    });

    test('successful own removal clears profile using user id', () async {
      await start();
      bloc.add(const FriendProfileRemoveRequested());
      await _settle();

      expect(repo.removeCalls, <String>[friendAnna.id]);
      expect(bloc.stateValue.removeStatus, LoadStatus.success);
      expect(bloc.stateValue.isNoLongerFriends, isTrue);
      expect(bloc.stateValue.profile, isNull);
    });

    test('completion after close does not emit', () async {
      final Completer<Either<Failure, FriendProfileEntity>> answer =
          Completer<Either<Failure, FriendProfileEntity>>();
      repo.onGetFriendProfile = (_) => answer.future;
      await start();
      final List<FriendProfileState> emitted = <FriendProfileState>[];
      final StreamSubscription<FriendProfileState> sub = bloc.stream.listen(
        emitted.add,
      );
      final Future<void> closing = bloc.close();
      await _settle();
      answer.complete(ok(profileOf(friendAnna)));
      await closing;
      await sub.cancel();

      expect(emitted, isEmpty);
    });
  });
}
