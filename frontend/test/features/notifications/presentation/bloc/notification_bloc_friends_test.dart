import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

import '../../../../helpers/friends_fakes.dart';
import '../../../../helpers/notification_fakes.dart';

const ActivityEntity _battleActivity = ActivityEntity(
  type: ActivityType.battle,
  resourceId: 'b9',
  battleId: 'b9',
  resourceKind: ActivityResourceKind.battle,
);

const ActivityEntity _roomActivity = ActivityEntity(
  type: ActivityType.privateDuel,
  resourceId: 'duel-1',
  battleId: null,
  resourceKind: ActivityResourceKind.duel,
);

Future<void> _flush(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump();
  }
}

Future<void> _advance(
  WidgetTester tester,
  FriendsNotificationFixture f,
  Duration by,
) async {
  f.now = f.now.add(by);
  await tester.pump(by);
  await _flush(tester);
}

Future<FriendsNotificationFixture> _started(
  WidgetTester tester, {
  void Function(FriendsNotificationFixture f)? setUp,
}) async {
  final FriendsNotificationFixture f = FriendsNotificationFixture();
  addTearDown(f.dispose);
  setUp?.call(f);
  f.bloc.add(const NotificationStarted());
  await _flush(tester);
  return f;
}

void _incomingRequests(
  FriendsNotificationFixture f,
  List<RelationshipEntity> items,
) {
  f.repo.onGetFriendRequests = (_) async => ok(requestsPage(items));
}

void _incomingInvitations(
  FriendsNotificationFixture f,
  List<DuelInvitationEntity> items,
) {
  f.repo.onGetIncomingDuelInvitations = () async => ok(snapshot(items));
}

Future<void> _pushRequest(
  WidgetTester tester,
  FriendsNotificationFixture f,
  RelationshipEntity r,
) async {
  f.repo.friendships.add(r);
  await _flush(tester);
}

Future<void> _pushInvitation(
  WidgetTester tester,
  FriendsNotificationFixture f,
  DuelInvitationEntity i,
) async {
  f.repo.invitations.add(i);
  await _flush(tester);
}

String _requestId(String id) => 'friendRequest:$id';
String _invitationId(String id) => 'duelInvitation:$id';

RelationshipEntity _requestOf(FriendsNotificationFixture f, String id) =>
    (f.state.item(_requestId(id))!.payload as FriendRequestNotificationPayload)
        .relationship;

DuelInvitationNotificationPayload _invitationPayload(
  FriendsNotificationFixture f,
  String id,
) =>
    f.state.item(_invitationId(id))!.payload
        as DuelInvitationNotificationPayload;

int _noticeCount(FriendsNotificationFixture f, NotificationNoticeType type) =>
    f.state.notices.where((NotificationNotice n) => n.type == type).length;

void main() {
  group('NotificationBloc friend requests', () {
    testWidgets('recovered incoming PENDING request becomes a prompt', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            _incomingRequests(f, <RelationshipEntity>[relationship('r1')]),
      );

      expect(f.state.prompts, hasLength(1));
      final NotificationItem item = f.state.item(_requestId('r1'))!;
      expect(item.kind, NotificationKind.friendRequest);
      expect(item.hasDeadline, isFalse);
      expect(f.repo.requestsCalls.single.size, 20);
    });

    testWidgets('stale and equal versions are ignored, newer is applied', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) => _incomingRequests(
          f,
          <RelationshipEntity>[relationship('r1', version: 2)],
        ),
      );

      await _pushRequest(
        tester,
        f,
        relationship('r1', version: 2, other: friendBoris),
      );
      expect(_requestOf(f, 'r1').requester, friendAnna);

      await _pushRequest(
        tester,
        f,
        relationship('r1', version: 1, other: friendBoris),
      );
      expect(_requestOf(f, 'r1').requester, friendAnna);

      await _pushRequest(
        tester,
        f,
        relationship('r1', version: 3, other: friendBoris),
      );
      expect(_requestOf(f, 'r1').requester, friendBoris);
    });

    testWidgets('a terminal push removes the card and leaves a tombstone', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            _incomingRequests(f, <RelationshipEntity>[relationship('r1')]),
      );

      await _pushRequest(
        tester,
        f,
        relationship('r1', status: RelationshipStatus.declined, version: 2),
      );
      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);

      // A late PENDING of the same id never reopens it, also not through a
      // lagging snapshot after a reconnect.
      await _pushRequest(tester, f, relationship('r1', version: 1));
      expect(f.state.items, isEmpty);
      _incomingRequests(f, <RelationshipEntity>[
        relationship('r1', version: 1),
        relationship('r2', version: 1),
      ]);
      f.reconnect();
      await _flush(tester);
      expect(f.state.item(_requestId('r1')), isNull);
      // A new relationship id after re-adding shows again.
      expect(f.state.item(_requestId('r2')), isNotNull);
    });

    testWidgets('a push that arrives during recovery and is newer than the '
        'snapshot wins', (WidgetTester tester) async {
      final Completer<Either<Failure, dynamic>> snapshotAnswer =
          Completer<Either<Failure, dynamic>>();
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onGetFriendRequests = (_) async {
            await snapshotAnswer.future;
            return ok(requestsPage(<RelationshipEntity>[relationship('r1')]));
          };
        },
      );

      await _pushRequest(
        tester,
        f,
        relationship('r1', status: RelationshipStatus.declined, version: 2),
      );
      snapshotAnswer.complete(ok<Object>(1));
      await _flush(tester);

      expect(f.state.item(_requestId('r1')), isNull);
    });

    testWidgets('a push that arrives during recovery and is older than the '
        'snapshot is dropped', (WidgetTester tester) async {
      final Completer<void> snapshotAnswer = Completer<void>();
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onGetFriendRequests = (_) async {
            await snapshotAnswer.future;
            return ok(
              requestsPage(<RelationshipEntity>[
                relationship('r1', version: 3),
              ]),
            );
          };
        },
      );

      await _pushRequest(
        tester,
        f,
        relationship('r1', status: RelationshipStatus.declined, version: 2),
      );
      snapshotAnswer.complete();
      await _flush(tester);

      expect(f.state.item(_requestId('r1')), isNotNull);
      expect(_requestOf(f, 'r1').version, 3);
    });

    testWidgets('a superseded recovery answer is dropped', (
      WidgetTester tester,
    ) async {
      final Completer<void> first = Completer<void>();
      int calls = 0;
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onGetFriendRequests = (_) async {
            final int call = ++calls;
            if (call == 1) {
              await first.future;
              return ok(
                requestsPage(<RelationshipEntity>[relationship('old')]),
              );
            }
            return ok(requestsPage(<RelationshipEntity>[relationship('new')]));
          };
        },
      );

      f.reconnect();
      await _flush(tester);
      first.complete();
      await _flush(tester);

      expect(f.state.items.map((NotificationItem i) => i.resourceId), <String>[
        'new',
      ]);
    });

    testWidgets('an account switch in the middle of a request drops its '
        'answer', (WidgetTester tester) async {
      final Completer<Either<Failure, RelationshipEntity>> accept =
          Completer<Either<Failure, RelationshipEntity>>();
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onAcceptFriendRequest = (_) => accept.future;
        },
      );

      f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
      await _flush(tester);
      expect(
        f.state.item(_requestId('r1'))!.action!.status,
        NotificationActionStatus.accepting,
      );

      _incomingRequests(f, <RelationshipEntity>[]);
      f.repo.userIds.add('another-user');
      await _flush(tester);
      expect(f.state.items, isEmpty);

      accept.complete(
        ok(relationship('r1', status: RelationshipStatus.accepted, version: 2)),
      );
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
      expect(f.repo.requestsCalls, hasLength(2));
    });

    testWidgets('a token refresh with the same user id keeps the state', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            _incomingRequests(f, <RelationshipEntity>[relationship('r1')]),
      );
      final NotificationState before = f.state;

      f.repo.userIds.add(testMeId);
      f.auth.changes.add(true);
      await _flush(tester);

      expect(f.state, before);
      expect(f.repo.requestsCalls, hasLength(1));
    });

    testWidgets('own Accept success shows Done and removes the card later', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onAcceptFriendRequest = (_) async => ok(
            relationship('r1', status: RelationshipStatus.accepted, version: 2),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
      await _flush(tester);

      final NotificationItem item = f.state.item(_requestId('r1'))!;
      expect((item.payload as FriendRequestNotificationPayload).isDone, isTrue);
      expect(item.isExpired, isTrue);
      expect(item.action, isNull);

      await _advance(tester, f, NotificationBloc.expiredLinger);
      expect(f.state.item(_requestId('r1')), isNull);
    });

    testWidgets('Decline removes the card without a notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onDeclineFriendRequest = (_) async => ok(
            relationship('r1', status: RelationshipStatus.declined, version: 2),
          );
        },
      );

      f.bloc.add(NotificationDeclineRequested(_requestId('r1')));
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('uncertain Accept re-reads: still pending becomes failed', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onAcceptFriendRequest = (_) async =>
              failed(const ConnectionFailure());
          f.repo.onGetFriendRequest = (_) async => ok(relationship('r1'));
        },
      );

      f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
      await _flush(tester);

      final NotificationAction action = f.state.item(_requestId('r1'))!.action!;
      expect(action.status, NotificationActionStatus.failed);
      expect(action.failure, const ConnectionFailure());
      expect(f.repo.getRequestCalls, <String>['r1']);
    });

    testWidgets('uncertain Accept re-read finds ACCEPTED: Done', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onAcceptFriendRequest = (_) async =>
              failed(const TimeoutFailure());
          f.repo.onGetFriendRequest = (_) async => ok(
            relationship('r1', status: RelationshipStatus.accepted, version: 2),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
      await _flush(tester);

      final NotificationItem item = f.state.item(_requestId('r1'))!;
      expect((item.payload as FriendRequestNotificationPayload).isDone, isTrue);
    });

    testWidgets('Accept 404 removes the card', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          f.repo.onAcceptFriendRequest = (_) async => failed(
            apiFailure(ApiErrorCodes.friendRequestNotFound, status: 404),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
      await _flush(tester);

      expect(f.state.items, isEmpty);
    });

    testWidgets('own outgoing request accepted raises one notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(tester);

      await _pushRequest(
        tester,
        f,
        relationship(
          'o1',
          incoming: false,
          status: RelationshipStatus.accepted,
          version: 2,
        ),
      );
      await _pushRequest(
        tester,
        f,
        relationship(
          'o1',
          incoming: false,
          status: RelationshipStatus.accepted,
          version: 3,
        ),
      );
      await _pushRequest(
        tester,
        f,
        relationship(
          'o2',
          incoming: false,
          status: RelationshipStatus.declined,
          version: 2,
        ),
      );

      expect(f.state.notices, hasLength(1));
      final NotificationNotice notice = f.state.notices.single;
      expect(notice.kind, NotificationKind.friendRequest);
      expect(notice.type, NotificationNoticeType.accepted);
      expect(notice.isOutgoing, isTrue);
      expect(notice.playerNickname, 'Anna');
      expect(f.state.items, isEmpty);
    });
  });

  group('NotificationBloc incoming room invitations', () {
    Future<FriendsNotificationFixture> withInvitation(
      WidgetTester tester, {
      void Function(FriendsNotificationFixture f)? setUp,
    }) => _started(
      tester,
      setUp: (FriendsNotificationFixture f) {
        _incomingInvitations(f, <DuelInvitationEntity>[invitation('i1')]);
        setUp?.call(f);
      },
    );

    testWidgets('recovered invitation is a prompt with a local deadline', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);

      final NotificationItem item = f.state.item(_invitationId('i1'))!;
      expect(item.isPrompt, isTrue);
      expect(item.hasDeadline, isTrue);
      expect(item.expiresAt, friendsNow.add(const Duration(seconds: 60)));
    });

    testWidgets('a server clock offset moves the local deadline', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onGetIncomingDuelInvitations = () async => ok(
            snapshot(<DuelInvitationEntity>[
              invitation('i1'),
            ], serverAhead: const Duration(seconds: 10)),
          );
        },
      );

      expect(
        f.state.item(_invitationId('i1'))!.expiresAt,
        friendsNow.add(const Duration(seconds: 50)),
      );
    });

    testWidgets('busy follows own activity other than NONE', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);
      expect(f.state.isBusy, isFalse);

      f.account.onGetActivity = () async => const Right(_roomActivity);
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      expect(f.state.isBusy, isTrue);

      f.account.onGetActivity = () async => const Right(ActivityEntity.none);
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      expect(f.state.isBusy, isFalse);
    });

    testWidgets('Accept with a battle id opens it and raises a notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async => ok(
            invitation(
              'i1',
              status: DuelInvitationStatus.accepted,
              version: 2,
              battleId: 'b1',
            ),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      expect(f.state.battleToOpen, 'b1');
      expect(f.state.item(_invitationId('i1')), isNull);
      expect(_noticeCount(f, NotificationNoticeType.accepted), 1);
      expect(f.state.notices.single.playerNickname, 'Anna');
    });

    testWidgets('uncertain Accept: re-read ACCEPTED opens the battle', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async =>
              failed(const ConnectionFailure());
          f.repo.onGetDuelInvitation = (_) async => ok(
            invitation(
              'i1',
              status: DuelInvitationStatus.accepted,
              version: 2,
              battleId: 'b1',
            ),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      expect(f.state.battleToOpen, 'b1');
      expect(f.state.item(_invitationId('i1')), isNull);
      expect(f.repo.getInvitationCalls, <String>['i1']);
    });

    testWidgets('uncertain Accept: still PENDING becomes failed', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async =>
              failed(const TimeoutFailure());
          f.repo.onGetDuelInvitation = (_) async => ok(invitation('i1'));
        },
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      final NotificationAction action = f.state
          .item(_invitationId('i1'))!
          .action!;
      expect(action.status, NotificationActionStatus.failed);
      expect(action.failure, const TimeoutFailure());
      expect(f.state.battleToOpen, isNull);
    });

    testWidgets('uncertain Accept: 404 with own BATTLE opens that battle', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async =>
              failed(const ConnectionFailure());
          f.repo.onGetDuelInvitation = (_) async => failed(
            apiFailure(ApiErrorCodes.duelInvitationNotFound, status: 404),
          );
          f.account.onGetActivity = () async => const Right(_battleActivity);
        },
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      expect(f.state.battleToOpen, 'b9');
      expect(f.state.item(_invitationId('i1')), isNull);
    });

    testWidgets('uncertain Accept: 404 otherwise shows room unavailable', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async =>
              failed(const ConnectionFailure());
          f.repo.onGetDuelInvitation = (_) async => failed(
            apiFailure(ApiErrorCodes.duelInvitationNotFound, status: 404),
          );
        },
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      final NotificationItem item = f.state.item(_invitationId('i1'))!;
      expect(item.isExpired, isTrue);
      expect(_invitationPayload(f, 'i1').isRoomUnavailable, isTrue);
      expect(f.state.battleToOpen, isNull);
    });

    testWidgets('the push before the HTTP answer opens the battle once', (
      WidgetTester tester,
    ) async {
      final Completer<Either<Failure, DuelInvitationEntity>> http =
          Completer<Either<Failure, DuelInvitationEntity>>();
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            f.repo.onAcceptDuelInvitation = (_) => http.future,
      );
      final DuelInvitationEntity accepted = invitation(
        'i1',
        status: DuelInvitationStatus.accepted,
        version: 2,
        battleId: 'b1',
      );
      final List<String?> opened = <String?>[];
      final StreamSubscription<NotificationState> sub = f.bloc.stream.listen(
        (NotificationState s) => opened.add(s.battleToOpen),
      );
      addTearDown(sub.cancel);

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);
      await _pushInvitation(tester, f, accepted);
      expect(f.state.battleToOpen, 'b1');

      f.bloc.add(const NotificationBattleOpened('b1'));
      await _flush(tester);
      http.complete(ok(accepted));
      await _flush(tester);

      expect(f.state.battleToOpen, isNull);
      expect(_noticeCount(f, NotificationNoticeType.accepted), 1);
      expect(opened.where((String? id) => id == 'b1'), isNotEmpty);
      expect(f.state.item(_invitationId('i1')), isNull);
    });

    testWidgets('the HTTP answer before the push opens the battle once', (
      WidgetTester tester,
    ) async {
      final DuelInvitationEntity accepted = invitation(
        'i1',
        status: DuelInvitationStatus.accepted,
        version: 2,
        battleId: 'b1',
      );
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            f.repo.onAcceptDuelInvitation = (_) async => ok(accepted),
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);
      expect(f.state.battleToOpen, 'b1');
      f.bloc.add(const NotificationBattleOpened('b1'));
      await _flush(tester);

      await _pushInvitation(tester, f, accepted);
      await _pushInvitation(
        tester,
        f,
        invitation(
          'i1',
          status: DuelInvitationStatus.accepted,
          version: 3,
          battleId: 'b1',
        ),
      );

      expect(f.state.battleToOpen, isNull);
      expect(_noticeCount(f, NotificationNoticeType.accepted), 1);
    });

    testWidgets('the room screen opening the battle first suppresses the '
        'overlay navigation', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await withInvitation(tester);

      f.bloc.add(const NotificationBattleOpened('b1'));
      await _flush(tester);
      f.repo.onAcceptDuelInvitation = (_) async => ok(
        invitation(
          'i1',
          status: DuelInvitationStatus.accepted,
          version: 2,
          battleId: 'b1',
        ),
      );
      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      expect(f.state.battleToOpen, isNull);
    });

    testWidgets('410 on Accept expires the card', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) =>
            f.repo.onAcceptDuelInvitation = (_) async => failed(
              apiFailure(ApiErrorCodes.duelInvitationExpired, status: 410),
            ),
      );

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      final NotificationItem item = f.state.item(_invitationId('i1'))!;
      expect(item.isExpired, isTrue);
      expect(item.action, isNull);
      expect(f.state.battleToOpen, isNull);

      await _advance(tester, f, NotificationBloc.expiredLinger);
      expect(f.state.item(_invitationId('i1')), isNull);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('ACTIVITY_CONFLICT fails the card and marks busy', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onAcceptDuelInvitation = (_) async =>
              failed(apiFailure(ApiErrorCodes.activityConflict));
        },
      );
      f.account.onGetActivity = () async => const Right(_roomActivity);

      f.bloc.add(NotificationAcceptRequested(_invitationId('i1')));
      await _flush(tester);

      final NotificationAction action = f.state
          .item(_invitationId('i1'))!
          .action!;
      expect(action.status, NotificationActionStatus.failed);
      expect(action.failure!.hasCode(ApiErrorCodes.activityConflict), isTrue);
      expect(f.state.isBusy, isTrue);
    });

    testWidgets('Decline removes the card without a toast', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onDeclineDuelInvitation = (_) async => ok(
            invitation('i1', status: DuelInvitationStatus.declined, version: 2),
          );
        },
      );

      f.bloc.add(NotificationDeclineRequested(_invitationId('i1')));
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('Decline with MATCH_ALREADY_FOUND re-reads the invitation', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.repo.onDeclineDuelInvitation = (_) async =>
              failed(apiFailure(ApiErrorCodes.matchAlreadyFound));
          f.repo.onGetDuelInvitation = (_) async => ok(
            invitation(
              'i1',
              status: DuelInvitationStatus.cancelled,
              reason: DuelInvitationReason.duelFilled,
              version: 2,
            ),
          );
        },
      );

      f.bloc.add(NotificationDeclineRequested(_invitationId('i1')));
      await _flush(tester);

      expect(_invitationPayload(f, 'i1').isRoomUnavailable, isTrue);
      expect(f.state.item(_invitationId('i1'))!.action, isNull);
    });

    testWidgets('CANCELLED by the sender removes the card with a notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);

      await _pushInvitation(
        tester,
        f,
        invitation(
          'i1',
          status: DuelInvitationStatus.cancelled,
          reason: DuelInvitationReason.senderCancelled,
          version: 2,
        ),
      );

      expect(f.state.item(_invitationId('i1')), isNull);
      expect(_noticeCount(f, NotificationNoticeType.cancelled), 1);
    });

    testWidgets('DUEL_CANCELLED on a visible card shows room unavailable', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);

      await _pushInvitation(
        tester,
        f,
        invitation(
          'i1',
          status: DuelInvitationStatus.cancelled,
          reason: DuelInvitationReason.duelCancelled,
          version: 2,
        ),
      );

      expect(f.state.item(_invitationId('i1'))!.isExpired, isTrue);
      expect(_invitationPayload(f, 'i1').isRoomUnavailable, isTrue);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('DUEL_FILLED on a hidden card is removed with a notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);
      f.bloc.add(NotificationHidden(_invitationId('i1')));
      await _flush(tester);

      await _pushInvitation(
        tester,
        f,
        invitation(
          'i1',
          status: DuelInvitationStatus.cancelled,
          reason: DuelInvitationReason.duelFilled,
          version: 2,
        ),
      );

      expect(f.state.item(_invitationId('i1')), isNull);
      expect(_noticeCount(f, NotificationNoticeType.cancelled), 1);
    });

    testWidgets('gone from a later snapshot shows room unavailable', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);
      _incomingInvitations(f, <DuelInvitationEntity>[]);

      f.reconnect();
      await _flush(tester);

      expect(f.state.item(_invitationId('i1'))!.isExpired, isTrue);
      expect(_invitationPayload(f, 'i1').isGone, isTrue);
    });

    testWidgets('a local deadline expires a visible card, then removes it', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await withInvitation(tester);

      await _advance(tester, f, const Duration(seconds: 61));
      expect(f.state.item(_invitationId('i1'))!.isExpired, isTrue);

      await _advance(tester, f, NotificationBloc.expiredLinger);
      expect(f.state.item(_invitationId('i1')), isNull);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('a local deadline removes a hidden card with an expired '
        'notice', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await withInvitation(tester);
      f.bloc.add(NotificationHidden(_invitationId('i1')));
      await _flush(tester);

      await _advance(tester, f, const Duration(seconds: 61));

      expect(f.state.item(_invitationId('i1')), isNull);
      expect(_noticeCount(f, NotificationNoticeType.expired), 1);
      expect(f.state.notices.single.isOutgoing, isFalse);
    });

    testWidgets('hide and show-hidden; a reconnect re-shows hidden prompts', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          _incomingRequests(f, <RelationshipEntity>[relationship('r1')]);
          _incomingInvitations(f, <DuelInvitationEntity>[invitation('i1')]);
        },
      );
      expect(f.state.prompts, hasLength(2));

      f.bloc.add(NotificationHidden(_requestId('r1')));
      f.bloc.add(NotificationHidden(_invitationId('i1')));
      await _flush(tester);
      expect(f.state.prompts, isEmpty);
      expect(f.state.hiddenCount, 2);

      f.bloc.add(const NotificationHiddenShown());
      await _flush(tester);
      expect(f.state.prompts, hasLength(2));
      expect(f.state.hiddenCount, 0);

      f.bloc.add(NotificationHidden(_requestId('r1')));
      await _flush(tester);
      expect(f.state.prompts, hasLength(1));

      f.reconnect();
      await _flush(tester);
      expect(f.state.prompts, hasLength(2));
    });
  });

  group('NotificationBloc host invitation', () {
    testWidgets('ACCEPTED opens the battle with an outgoing notice', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(
        tester,
        f,
        invitation('o1', incoming: false, other: friendBoris),
      );
      expect(f.state.item(_invitationId('o1'))!.isPrompt, isFalse);
      expect(f.state.prompts, isEmpty);

      await _pushInvitation(
        tester,
        f,
        invitation(
          'o1',
          incoming: false,
          other: friendBoris,
          status: DuelInvitationStatus.accepted,
          version: 2,
          battleId: 'b1',
        ),
      );

      expect(f.state.battleToOpen, 'b1');
      expect(f.state.item(_invitationId('o1')), isNull);
      final NotificationNotice notice = f.state.notices.single;
      expect(notice.type, NotificationNoticeType.accepted);
      expect(notice.isOutgoing, isTrue);
      expect(notice.playerNickname, 'Boris');
    });

    final Map<String, (DuelInvitationStatus, DuelInvitationReason?)> noticed =
        <String, (DuelInvitationStatus, DuelInvitationReason?)>{
          'declined': (DuelInvitationStatus.declined, null),
          'expired': (DuelInvitationStatus.expired, null),
          'cancelled': (
            DuelInvitationStatus.cancelled,
            DuelInvitationReason.duelFilled,
          ),
          'cancelledFriendRemoved': (
            DuelInvitationStatus.cancelled,
            DuelInvitationReason.friendRemoved,
          ),
        };
    for (final MapEntry<String, (DuelInvitationStatus, DuelInvitationReason?)>
        entry
        in noticed.entries) {
      testWidgets('${entry.key} raises exactly one outgoing notice', (
        WidgetTester tester,
      ) async {
        final FriendsNotificationFixture f = await _started(tester);
        final (DuelInvitationStatus status, DuelInvitationReason? reason) =
            entry.value;

        for (final int version in <int>[2, 3]) {
          await _pushInvitation(
            tester,
            f,
            invitation(
              'o1',
              incoming: false,
              status: status,
              reason: reason,
              version: version,
            ),
          );
        }

        expect(f.state.notices, hasLength(1));
        final NotificationNotice notice = f.state.notices.single;
        expect(notice.isOutgoing, isTrue);
        expect(notice.invitationReason, reason);
        expect(f.state.battleToOpen, isNull);
      });
    }

    for (final DuelInvitationReason reason in <DuelInvitationReason>[
      DuelInvitationReason.senderCancelled,
      DuelInvitationReason.duelCancelled,
    ]) {
      testWidgets('own ${reason.name} raises no notice', (
        WidgetTester tester,
      ) async {
        final FriendsNotificationFixture f = await _started(tester);
        await _pushInvitation(tester, f, invitation('o1', incoming: false));

        await _pushInvitation(
          tester,
          f,
          invitation(
            'o1',
            incoming: false,
            status: DuelInvitationStatus.cancelled,
            reason: reason,
            version: 2,
          ),
        );

        expect(f.state.notices, isEmpty);
        expect(f.state.item(_invitationId('o1')), isNull);
      });
    }

    testWidgets('the local deadline of an own invitation raises expired', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(tester, f, invitation('o1', incoming: false));

      await _advance(tester, f, const Duration(seconds: 61));

      expect(f.state.item(_invitationId('o1')), isNull);
      final NotificationNotice notice = f.state.notices.single;
      expect(notice.type, NotificationNoticeType.expired);
      expect(notice.isOutgoing, isTrue);

      // The later server EXPIRED must not repeat the toast.
      await _pushInvitation(
        tester,
        f,
        invitation(
          'o1',
          incoming: false,
          status: DuelInvitationStatus.expired,
          version: 2,
        ),
      );
      expect(f.state.notices, hasLength(1));
    });

    testWidgets('a lost ACCEPTED push is found when the room leaves the '
        'activity', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(tester, f, invitation('o1', incoming: false));
      f.repo.onGetDuelInvitation = (_) async => ok(
        invitation(
          'o1',
          incoming: false,
          status: DuelInvitationStatus.accepted,
          version: 2,
          battleId: 'b1',
        ),
      );
      f.account.onGetActivity = () async => const Right(ActivityEntity.none);

      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);

      expect(f.state.battleToOpen, 'b1');
      expect(f.repo.getInvitationCalls, <String>['o1']);
    });

    testWidgets('route change with invitation 404 restores the activity battle '
        'exactly once', (WidgetTester tester) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(tester, f, invitation('o1', incoming: false));
      f.account.onGetActivity = () async => const Right(_battleActivity);
      f.repo.onGetDuelInvitation = (_) async =>
          failed(apiFailure(ApiErrorCodes.duelInvitationNotFound, status: 404));

      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);

      expect(f.state.battleToOpen, 'b9');
      expect(f.state.item(_invitationId('o1')), isNull);
      expect(f.state.notices.single.isOutgoing, isTrue);
      expect(f.state.notices.single.type, NotificationNoticeType.accepted);

      f.bloc.add(const NotificationBattleOpened('b9'));
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      f.reconnect();
      await _flush(tester);

      expect(f.state.battleToOpen, isNull);
      expect(_noticeCount(f, NotificationNoticeType.accepted), 1);
    });

    testWidgets('a newer activity read supersedes a pending host check', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(tester, f, invitation('o1', incoming: false));
      final Completer<Either<Failure, DuelInvitationEntity>> oldCheck =
          Completer<Either<Failure, DuelInvitationEntity>>();
      f.account.onGetActivity = () async => const Right(_battleActivity);
      f.repo.onGetDuelInvitation = (_) => oldCheck.future;

      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      expect(f.repo.getInvitationCalls, <String>['o1']);

      f.account.onGetActivity = () async => const Right(_roomActivity);
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      oldCheck.complete(
        failed(apiFailure(ApiErrorCodes.duelInvitationNotFound, status: 404)),
      );
      await _flush(tester);

      expect(f.state.battleToOpen, isNull);
      expect(f.state.item(_invitationId('o1')), isNotNull);
      expect(f.state.notices, isEmpty);
    });

    testWidgets('recovery restores the room invitation of a waiting room', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(
        tester,
        setUp: (FriendsNotificationFixture f) {
          f.account.onGetActivity = () async => const Right(_roomActivity);
          f.repo.onGetRoomInvitations = (_) async => ok(
            snapshot(<DuelInvitationEntity>[invitation('o1', incoming: false)]),
          );
        },
      );

      expect(f.repo.roomCalls, <String>['duel-1']);
      expect(f.state.item(_invitationId('o1'))!.isPrompt, isFalse);
      expect(f.state.isBusy, isTrue);
    });

    testWidgets('recovery with 404 and own BATTLE opens the lost battle', (
      WidgetTester tester,
    ) async {
      final FriendsNotificationFixture f = await _started(tester);
      await _pushInvitation(tester, f, invitation('o1', incoming: false));
      f.account.onGetActivity = () async => const Right(_battleActivity);
      f.repo.onGetDuelInvitation = (_) async =>
          failed(apiFailure(ApiErrorCodes.duelInvitationNotFound, status: 404));

      f.reconnect();
      await _flush(tester);

      expect(f.state.battleToOpen, 'b9');
      expect(f.state.item(_invitationId('o1')), isNull);
    });
  });

  test('closing while an Accept is awaited neither throws nor emits', () async {
    final FriendsNotificationFixture f = FriendsNotificationFixture();
    f.repo.onGetFriendRequests = (_) async =>
        ok(requestsPage(<RelationshipEntity>[relationship('r1')]));
    final Completer<Either<Failure, RelationshipEntity>> accept =
        Completer<Either<Failure, RelationshipEntity>>();
    f.repo.onAcceptFriendRequest = (_) => accept.future;
    f.bloc.add(const NotificationStarted());
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    f.bloc.add(NotificationAcceptRequested(_requestId('r1')));
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final List<NotificationState> emitted = <NotificationState>[];
    final StreamSubscription<NotificationState> sub = f.bloc.stream.listen(
      emitted.add,
    );
    final Future<void> closing = f.bloc.close();
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    accept.complete(
      ok(relationship('r1', status: RelationshipStatus.accepted, version: 2)),
    );
    await closing;
    await sub.cancel();

    expect(emitted, isEmpty);
    expect(f.bloc.isClosed, isTrue);
    f.dispose();
  });
}
