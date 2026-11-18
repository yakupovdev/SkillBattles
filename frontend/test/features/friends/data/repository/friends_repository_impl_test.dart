import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/error/app_exception.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/core/utils/storage/token_storage.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitation_model.dart';
import 'package:skill_battles/features/friends/data/models/relationship_model.dart';
import 'package:skill_battles/features/friends/data/repository/friends_repository_impl.dart';
import 'package:skill_battles/features/friends/data/sources/remote/friends_remote.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

const SessionTokens _accountA = SessionTokens(
  accessToken: 'access-a',
  refreshToken: 'refresh-a',
  userId: 'account-a',
);
const SessionTokens _accountB = SessionTokens(
  accessToken: 'access-b',
  refreshToken: 'refresh-b',
  userId: 'account-b',
);

final class _Realtime implements RealtimeClient {
  @override
  Stream<RealtimeEnvelope> get events => const Stream<RealtimeEnvelope>.empty();

  @override
  Stream<RealtimeStatus> get statusChanges =>
      const Stream<RealtimeStatus>.empty();

  @override
  RealtimeStatus get status => RealtimeStatus.connected;

  @override
  void start() {}

  @override
  Future<void> dispose() async {}
}

final class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 15, 12);
}

final class _Remote implements FriendsRemote {
  Future<RelationshipModel> Function(String id)? onAcceptRequest;
  Future<DuelInvitationModel> Function(String id)? onAcceptInvitation;

  @override
  Future<RelationshipModel> acceptFriendRequest(String requestId) =>
      onAcceptRequest!(requestId);

  @override
  Future<DuelInvitationModel> acceptDuelInvitation(String invitationId) =>
      onAcceptInvitation!(invitationId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Map<String, dynamic> _player(String id) => <String, dynamic>{
  'id': id,
  'nickname': id,
  'isPro': false,
};

RelationshipModel _relationship() =>
    RelationshipModel.fromJson(<String, dynamic>{
      'id': 'request-1',
      'requester': _player('sender'),
      'recipient': _player('account-a'),
      'status': 'ACCEPTED',
      'createdAt': '2026-11-15T12:00:00Z',
      'updatedAt': '2026-11-15T12:00:01Z',
      'acceptedAt': '2026-11-15T12:00:01Z',
      'version': 2,
    });

DuelInvitationModel _invitation() =>
    DuelInvitationModel.fromJson(<String, dynamic>{
      'id': 'invitation-1',
      'duelId': 'duel-1',
      'host': _player('sender'),
      'recipient': _player('account-a'),
      'disciplineCode': 'MATH',
      'format': 'STANDARD',
      'status': 'ACCEPTED',
      'reason': null,
      'createdAt': '2026-11-15T12:00:00Z',
      'expiresAt': '2026-11-15T12:01:00Z',
      'battleId': 'battle-a',
      'version': 2,
    });

void main() {
  late _Remote remote;
  late AuthSession session;
  late FriendsRepositoryImpl repository;
  late List<RelationshipEntity> relationships;
  late List<DuelInvitationEntity> invitations;
  late StreamSubscription<RelationshipEntity> relationshipSub;
  late StreamSubscription<DuelInvitationEntity> invitationSub;

  setUp(() async {
    remote = _Remote();
    session = AuthSession(
      storage: MemoryTokenStorage(),
      refresher: (_) async => _accountA,
    );
    await session.signIn(_accountA);
    repository = FriendsRepositoryImpl(
      remote: remote,
      realtime: _Realtime(),
      session: session,
      clock: _Clock(),
    );
    relationships = <RelationshipEntity>[];
    invitations = <DuelInvitationEntity>[];
    relationshipSub = repository.watchFriendshipChanges().listen(
      relationships.add,
    );
    invitationSub = repository.watchDuelInvitationChanges().listen(
      invitations.add,
    );
  });

  tearDown(() async {
    await relationshipSub.cancel();
    await invitationSub.cancel();
    await repository.dispose();
    session.dispose();
  });

  group('FriendsRepositoryImpl account isolation', () {
    test(
      'old friend accept preserves direction without publishing to new account',
      () async {
        final Completer<RelationshipModel> answer =
            Completer<RelationshipModel>();
        remote.onAcceptRequest = (_) => answer.future;
        final pending = repository.acceptFriendRequest('request-1');
        await session.signIn(_accountB);
        answer.complete(_relationship());
        final result = await pending;
        await Future<void>.delayed(Duration.zero);

        expect(result.toNullable()!.direction, FriendRequestDirection.incoming);
        expect(relationships, isEmpty);
      },
    );

    test(
      'old invitation accept never publishes foreign battle to new account',
      () async {
        final Completer<DuelInvitationModel> answer =
            Completer<DuelInvitationModel>();
        remote.onAcceptInvitation = (_) => answer.future;
        final pending = repository.acceptDuelInvitation('invitation-1');
        await session.signIn(_accountB);
        answer.complete(_invitation());
        final result = await pending;
        await Future<void>.delayed(Duration.zero);

        expect(result.toNullable()!.isIncoming, isTrue);
        expect(result.toNullable()!.battleId, 'battle-a');
        expect(invitations, isEmpty);
      },
    );

    test(
      'same-account token rotation keeps publishing accepted invitation',
      () async {
        final Completer<DuelInvitationModel> answer =
            Completer<DuelInvitationModel>();
        remote.onAcceptInvitation = (_) => answer.future;
        final pending = repository.acceptDuelInvitation('invitation-1');
        await session.signIn(
          const SessionTokens(
            accessToken: 'rotated-access',
            refreshToken: 'rotated-refresh',
            userId: 'account-a',
          ),
        );
        answer.complete(_invitation());
        final result = await pending;
        await Future<void>.delayed(Duration.zero);

        expect(invitations, <DuelInvitationEntity>[result.toNullable()!]);
        expect(invitations.single.isIncoming, isTrue);
      },
    );

    test(
      'same-account friend accept publishes mapped command result',
      () async {
        remote.onAcceptRequest = (_) async => _relationship();
        final result = await repository.acceptFriendRequest('request-1');
        await Future<void>.delayed(Duration.zero);

        expect(relationships, <RelationshipEntity>[result.toNullable()!]);
        expect(relationships.single.direction, FriendRequestDirection.incoming);
      },
    );

    test('parsing exception becomes typed failure and emits nothing', () async {
      remote.onAcceptRequest = (_) async =>
          throw const ParsingException('bad record');
      final result = await repository.acceptFriendRequest('request-1');
      await Future<void>.delayed(Duration.zero);

      expect(result.getLeft(), isA<ParsingFailure>());
      expect(relationships, isEmpty);
    });

    test(
      'programming errors propagate without conversion to Failure',
      () async {
        remote.onAcceptRequest = (_) async => throw StateError('test defect');
        await expectLater(
          repository.acceptFriendRequest('request-1'),
          throwsStateError,
        );
        expect(relationships, isEmpty);
      },
    );
  });
}
