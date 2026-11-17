import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/withdraw_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/room_invitation_bloc/room_invitation_bloc.dart';

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
  late RoomInvitationBloc bloc;

  setUp(() {
    repo = ScriptedFriendsRepository();
    connection = FakeConnectionRepository();
    bloc = RoomInvitationBloc(
      getRoomInvitations: GetRoomInvitationsUsecase(repo),
      getDuelInvitation: GetDuelInvitationUsecase(repo),
      sendDuelInvitation: SendDuelInvitationUsecase(repo),
      withdrawDuelInvitation: WithdrawDuelInvitationUsecase(repo),
      getFriends: GetFriendsUsecase(repo),
      watchDuelInvitationChanges: WatchDuelInvitationChangesUsecase(repo),
      watchConnection: WatchConnectionUsecase(connection),
      generateId: sequentialIds(),
      pageSize: 2,
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.dispose();
    await connection.changes.close();
  });

  Future<void> send(RoomInvitationEvent event) async {
    bloc.add(event);
    await _settle();
  }

  Future<void> start() => send(const RoomInvitationStarted('duel-1'));

  group('RoomInvitationBloc send intent', () {
    test(
      'uncertain retry reuses id and another target gets fresh id',
      () async {
        await start();
        repo.onSendDuelInvitation = (_) async => failed(const TimeoutFailure());

        await send(RoomInvitationSendRequested(friendAnna.id));
        expect(bloc.stateValue.canRetrySend, isTrue);
        await send(RoomInvitationSendRequested(friendAnna.id));
        await send(RoomInvitationSendRequested(friendBoris.id));

        expect(repo.sendInvitationCalls.map((p) => p.requestId), <String>[
          'id-1',
          'id-1',
          'id-2',
        ]);
        expect(
          repo.sendInvitationCalls.map((p) => p.duelId),
          everyElement('duel-1'),
        );
      },
    );

    test(
      'definite rejection ends intent for later send to same friend',
      () async {
        await start();
        repo.onSendDuelInvitation = (_) async =>
            failed(apiFailure(ApiErrorCodes.friendNotFound, status: 404));

        await send(RoomInvitationSendRequested(friendAnna.id));
        expect(bloc.stateValue.canRetrySend, isFalse);
        await send(RoomInvitationSendRequested(friendAnna.id));

        expect(repo.sendInvitationCalls.map((p) => p.requestId), <String>[
          'id-1',
          'id-2',
        ]);
      },
    );

    test('terminal replay is resolved and next send uses fresh id', () async {
      await start();
      repo.onSendDuelInvitation = (_) async => ok(
        invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.declined,
        ),
      );
      await send(RoomInvitationSendRequested(friendAnna.id));
      await send(const RoomInvitationResultCleared());
      await send(RoomInvitationSendRequested(friendAnna.id));

      expect(repo.sendInvitationCalls.map((p) => p.requestId), <String>[
        'id-1',
        'id-2',
      ]);
    });

    test('push after timeout resolves intent and clears retry', () async {
      await start();
      repo.onSendDuelInvitation = (_) async => failed(const TimeoutFailure());
      await send(RoomInvitationSendRequested(friendAnna.id));
      repo.invitations.add(
        invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.declined,
        ),
      );
      await _settle();

      expect(bloc.stateValue.canRetrySend, isFalse);
      expect(bloc.stateValue.sendStatus, LoadStatus.success);
      expect(bloc.stateValue.sendFailure, isNull);
      await send(RoomInvitationSendRequested(friendAnna.id));
      expect(repo.sendInvitationCalls.last.requestId, 'id-2');
    });

    test(
      'terminal push before timeout resolves intent and forbids old retry',
      () async {
        await start();
        final Completer<Either<Failure, DuelInvitationEntity>> answer =
            Completer<Either<Failure, DuelInvitationEntity>>();
        repo.onSendDuelInvitation = (_) => answer.future;
        await send(RoomInvitationSendRequested(friendAnna.id));
        final DuelInvitationEntity terminal = invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.declined,
          version: 2,
        );
        repo.invitations.add(terminal);
        await _settle();
        answer.complete(failed(const TimeoutFailure()));
        await _settle();

        expect(bloc.stateValue.invitation, terminal);
        expect(bloc.stateValue.canRetrySend, isFalse);
        expect(bloc.stateValue.sendStatus, LoadStatus.success);
        expect(bloc.stateValue.sendFailure, isNull);
        repo.onSendDuelInvitation = (_) async => failed(const TimeoutFailure());
        await send(RoomInvitationSendRequested(friendAnna.id));
        expect(repo.sendInvitationCalls.last.requestId, 'id-2');
      },
    );

    for (final bool oldRequestFails in <bool>[true, false]) {
      test('a terminal push allows another send before the old HTTP '
          '${oldRequestFails ? 'failure' : 'success'} completes', () async {
        await start();
        final Completer<Either<Failure, DuelInvitationEntity>> first =
            Completer<Either<Failure, DuelInvitationEntity>>();
        final Completer<Either<Failure, DuelInvitationEntity>> second =
            Completer<Either<Failure, DuelInvitationEntity>>();
        repo.onSendDuelInvitation = (_) => first.future;
        await send(RoomInvitationSendRequested(friendAnna.id));
        repo.invitations.add(
          invitation(
            'i1',
            incoming: false,
            status: DuelInvitationStatus.declined,
            version: 2,
          ),
        );
        await _settle();

        repo.onSendDuelInvitation = (_) => second.future;
        await send(RoomInvitationSendRequested(friendAnna.id));
        final List<String> requestIds = repo.sendInvitationCalls
            .map((p) => p.requestId)
            .toList();
        first.complete(
          oldRequestFails
              ? failed(const TimeoutFailure())
              : ok(invitation('i1', incoming: false)),
        );
        await _settle();
        final LoadStatus statusAfterOldAnswer = bloc.stateValue.sendStatus;
        second.complete(
          ok(
            invitation(
              'i2',
              incoming: false,
              createdAt: friendsNow.add(const Duration(seconds: 1)),
            ),
          ),
        );
        await _settle();

        expect(requestIds, <String>['id-1', 'id-2']);
        expect(statusAfterOldAnswer, LoadStatus.loading);
        expect(bloc.stateValue.invitation!.id, 'i2');
        expect(bloc.stateValue.sendStatus, LoadStatus.success);
        expect(bloc.stateValue.canRetrySend, isFalse);
      });
    }

    test(
      'a replay after dismissing the old result cannot resolve a new send',
      () async {
        await start();
        final Completer<Either<Failure, DuelInvitationEntity>> first =
            Completer<Either<Failure, DuelInvitationEntity>>();
        final Completer<Either<Failure, DuelInvitationEntity>> second =
            Completer<Either<Failure, DuelInvitationEntity>>();
        repo.onSendDuelInvitation = (_) => first.future;
        await send(RoomInvitationSendRequested(friendAnna.id));
        final DuelInvitationEntity oldResult = invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.declined,
          version: 2,
        );
        repo.invitations.add(oldResult);
        await _settle();
        await send(const RoomInvitationResultCleared());
        repo.onSendDuelInvitation = (_) => second.future;
        await send(RoomInvitationSendRequested(friendAnna.id));

        // Real repositories re-emit HTTP results through this stream too.
        repo.invitations.add(oldResult);
        repo.invitations.add(invitation('i1', incoming: false));
        first.complete(ok(oldResult));
        await _settle();
        final LoadStatus statusAfterReplay = bloc.stateValue.sendStatus;
        final DuelInvitationEntity? resultAfterReplay = bloc.stateValue.invitation;
        second.complete(
          ok(
            invitation(
              'i2',
              incoming: false,
              createdAt: friendsNow.add(const Duration(seconds: 1)),
            ),
          ),
        );
        await _settle();

        expect(statusAfterReplay, LoadStatus.loading);
        expect(resultAfterReplay, isNull);
        expect(repo.sendInvitationCalls.map((p) => p.requestId), <String>[
          'id-1',
          'id-2',
        ]);
        expect(bloc.stateValue.invitation!.id, 'i2');
      },
    );

    test('newer terminal invitation wins over an older pending invitation '
        'and its late stream replay', () async {
      await start();
      repo.invitations.add(invitation('old', incoming: false));
      await _settle();
      final DuelInvitationEntity newest = invitation(
        'new',
        incoming: false,
        createdAt: friendsNow.add(const Duration(seconds: 1)),
        status: DuelInvitationStatus.declined,
        version: 2,
      );
      repo.invitations.add(newest);
      await _settle();
      expect(bloc.stateValue.invitation, newest);

      repo.invitations.add(invitation('old', incoming: false));
      repo.invitations.add(
        invitation(
          'old',
          incoming: false,
          status: DuelInvitationStatus.declined,
          version: 3,
        ),
      );
      await _settle();
      expect(bloc.stateValue.invitation, newest);
      expect(bloc.stateValue.pendingInvitation, isNull);
    });

    test('an unresolved send blocks duplicate sends', () async {
      await start();
      final Completer<Either<Failure, DuelInvitationEntity>> answer =
          Completer<Either<Failure, DuelInvitationEntity>>();
      repo.onSendDuelInvitation = (_) => answer.future;
      await send(RoomInvitationSendRequested(friendAnna.id));
      await send(RoomInvitationSendRequested(friendBoris.id));
      final int calls = repo.sendInvitationCalls.length;
      answer.complete(ok(invitation('i1', incoming: false)));
      await _settle();

      expect(calls, 1);
      expect(bloc.stateValue.pendingInvitation!.id, 'i1');
    });

    test('pending invitation blocks duplicate send', () async {
      await start();
      repo.onSendDuelInvitation = (_) async =>
          ok(invitation('i1', incoming: false));
      await send(RoomInvitationSendRequested(friendAnna.id));
      await send(RoomInvitationSendRequested(friendBoris.id));

      expect(repo.sendInvitationCalls, hasLength(1));
      expect(bloc.stateValue.canInvite, isFalse);
    });
  });

  group('RoomInvitationBloc withdraw', () {
    Future<void> withPending() async {
      repo.onGetRoomInvitations = (_) async =>
          ok(snapshot([invitation('i1', incoming: false)]));
      await start();
    }

    test('204 rereads invitation and enables another invite', () async {
      await withPending();
      repo.onGetDuelInvitation = (_) async => ok(
        invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.cancelled,
          reason: DuelInvitationReason.senderCancelled,
          version: 2,
        ),
      );
      await send(const RoomInvitationWithdrawRequested());

      expect(repo.withdrawCalls, <String>['i1']);
      expect(repo.getInvitationCalls, <String>['i1']);
      expect(bloc.stateValue.withdrawStatus, LoadStatus.success);
      expect(bloc.stateValue.pendingInvitation, isNull);
      expect(bloc.stateValue.canInvite, isTrue);
    });

    test('MATCH_ALREADY_FOUND rereads accepted result', () async {
      await withPending();
      repo.onWithdrawDuelInvitation = (_) async =>
          failed(apiFailure(ApiErrorCodes.matchAlreadyFound));
      repo.onGetDuelInvitation = (_) async => ok(
        invitation(
          'i1',
          incoming: false,
          status: DuelInvitationStatus.accepted,
          battleId: 'battle-1',
          version: 2,
        ),
      );
      await send(const RoomInvitationWithdrawRequested());

      expect(bloc.stateValue.invitation!.battleId, 'battle-1');
      expect(bloc.stateValue.withdrawFailure, isNull);
      expect(bloc.stateValue.pendingInvitation, isNull);
    });
  });

  group('RoomInvitationBloc picker', () {
    Future<void> open() async {
      await start();
      repo.onGetFriends = (p) async => ok(
        friendsPage(
          [friendItem('rel-${p.page}', p.page == 0 ? friendAnna : friendBoris)],
          page: p.page,
          totalPages: 2,
          totalElements: 3,
        ),
      );
      await send(const RoomInvitationFriendsRequested());
    }

    test(
      'page load keeps old data then replaces it without appending',
      () async {
        await open();
        final Completer<Either<Failure, FriendsPageEntity>> answer =
            Completer<Either<Failure, FriendsPageEntity>>();
        repo.onGetFriends = (_) => answer.future;
        await send(const RoomInvitationFriendsPageRequested(1));

        expect(bloc.stateValue.friendsPageStatus, LoadStatus.loading);
        expect(bloc.stateValue.friends.single.friend, friendAnna);
        answer.complete(
          ok(
            friendsPage(
              [friendItem('rel-1', friendBoris)],
              page: 1,
              totalPages: 2,
              totalElements: 3,
            ),
          ),
        );
        await _settle();

        expect(bloc.stateValue.friendsPageStatus, LoadStatus.success);
        expect(bloc.stateValue.friends.single.friend, friendBoris);
        expect(bloc.stateValue.friendsPage!.page, 1);
        expect(repo.friendsCalls.last.size, 2);
      },
    );

    test('reopening picker supersedes an awaited page response', () async {
      await open();
      final Completer<Either<Failure, FriendsPageEntity>> old =
          Completer<Either<Failure, FriendsPageEntity>>();
      repo.onGetFriends = (_) => old.future;
      await send(const RoomInvitationFriendsPageRequested(1));
      repo.onGetFriends = (_) async =>
          ok(friendsPage([friendItem('fresh', friendAnna)], totalPages: 1));
      await send(const RoomInvitationFriendsRequested());
      old.complete(
        ok(
          friendsPage(
            [friendItem('stale', friendBoris)],
            page: 1,
            totalPages: 2,
          ),
        ),
      );
      await _settle();

      expect(bloc.stateValue.friends.single.relationshipId, 'fresh');
      expect(bloc.stateValue.friendsPage!.page, 0);
      expect(bloc.stateValue.friendsPageStatus, LoadStatus.initial);
    });

    test('page failure keeps current data and can be retried', () async {
      await open();
      repo.onGetFriends = (_) async => failed(const TimeoutFailure());
      await send(const RoomInvitationFriendsPageRequested(1));

      expect(bloc.stateValue.friends.single.friend, friendAnna);
      expect(bloc.stateValue.friendsPageStatus, LoadStatus.failure);
      expect(bloc.stateValue.friendsPageFailure, const TimeoutFailure());
      repo.onGetFriends = (_) async => ok(
        friendsPage([friendItem('rel-1', friendBoris)], page: 1, totalPages: 2),
      );
      await send(const RoomInvitationFriendsPageRequested(1));

      expect(bloc.stateValue.friendsPageFailure, isNull);
      expect(bloc.stateValue.friends.single.friend, friendBoris);
    });
  });
}
