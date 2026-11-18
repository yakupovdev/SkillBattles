import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

import '../../../../helpers/fake_timers.dart';
import '../../../../helpers/notification_fakes.dart';

const String _id = 'rematch:b1';

/// Lets queued events, stream deliveries and futures run.
Future<void> _flush(FakeTimers tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump();
  }
}

/// Real-async variant of [_flush] for tests that close the bloc.
Future<void> _settle() async {
  for (int i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Moves the injected clock and the fake timers together.
Future<void> _advance(
  FakeTimers tester,
  NotificationFixture f,
  Duration by,
) async {
  f.now = f.now.add(by);
  await tester.pump(by);
  await _flush(tester);
}

Future<NotificationFixture> _started(
  FakeTimers tester, {
  bool signedIn = true,
}) async {
  final NotificationFixture f = NotificationFixture(signedIn: signedIn);
  addTearDown(f.dispose);
  f.bloc.add(const NotificationStarted());
  await _flush(tester);
  return f;
}

Future<void> _push(
  FakeTimers tester,
  NotificationFixture f,
  RematchEntity entity,
) async {
  f.results.rematches.add(entity);
  await _flush(tester);
}

NotificationItem _item(NotificationFixture f, [String id = _id]) =>
    f.state.items.firstWhere((NotificationItem i) => i.id == id);

RematchNotificationPayload _payload(NotificationItem item) =>
    item.payload as RematchNotificationPayload;

void main() {
  group('NotificationBloc', () {
    fakeTimersTest('starts empty, disconnected-aware and reads activity', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
      expect(f.state.battleToOpen, isNull);
      expect(f.account.activityCalls, 1);
    });

    fakeTimersTest('incoming waiting rematch becomes a prompt with details', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);

      await _push(tester, f, rematch('b1'));

      expect(f.state.prompts, hasLength(1));
      final NotificationItem item = _item(f);
      expect(item.isPrompt, isTrue);
      expect(item.id, _id);
      expect(_payload(item).isIncoming, isTrue);
      expect(_payload(item).opponentNickname, testNickname);
      expect(_payload(item).disciplineCode, testDiscipline);
      expect(f.results.getResultCalls, <String>['b1']);
    });

    fakeTimersTest('own outgoing rematch is tracked but is not a prompt', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);

      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));

      expect(f.state.prompts, isEmpty);
      expect(_item(f).isPrompt, isFalse);
      expect(_payload(_item(f)).isIncoming, isFalse);
    });

    fakeTimersTest('holds the rematch back until the own id is known', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      final Completer<Either<Failure, BattleResultEntity>> pending =
          Completer<Either<Failure, BattleResultEntity>>();
      f.results.onGetResult = (_) => pending.future;

      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));
      expect(f.state.items, isEmpty);

      pending.complete(Right(battleResult('b1')));
      await _flush(tester);

      expect(f.state.items, hasLength(1));
      expect(_item(f).isPrompt, isFalse);
    });

    fakeTimersTest('shows the rematch as incoming when getResult fails', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      f.results.onGetResult = (_) async => const Left(ConnectionFailure());

      await _push(tester, f, rematch('b1'));

      expect(f.state.prompts, hasLength(1));
      expect(_payload(_item(f)).opponentNickname, isNull);
      expect(_payload(_item(f)).disciplineCode, isNull);
    });

    fakeTimersTest('a late lower version after removal does not reopen it', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', version: 2));
      await _push(
        tester,
        f,
        rematch('b1', status: RematchStatus.cancelled, version: 3),
      );
      expect(f.state.items, isEmpty);

      await _push(tester, f, rematch('b1', version: 1));
      await _push(tester, f, rematch('b1', version: 3));

      expect(f.state.items, isEmpty);
    });

    fakeTimersTest('a lower version is ignored while the item is live', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', version: 5));

      await _push(
        tester,
        f,
        rematch('b1', status: RematchStatus.cancelled, version: 4),
      );

      expect(f.state.items, hasLength(1));
      expect(f.state.notices, isEmpty);
    });

    fakeTimersTest('MATCHED removes the item, opens the battle once, notices', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));

      final RematchEntity matched = rematch(
        'b1',
        status: RematchStatus.matched,
        version: 2,
        battleId: 'new1',
      );
      await _push(tester, f, matched);

      expect(f.state.items, isEmpty);
      expect(f.state.battleToOpen, 'new1');
      expect(f.state.notices, hasLength(1));
      expect(f.state.notices.single.type, NotificationNoticeType.accepted);
      expect(f.state.notices.single.playerNickname, testNickname);

      f.bloc.add(const NotificationBattleOpened('new1'));
      await _flush(tester);
      expect(f.state.battleToOpen, isNull);

      // The same battle is not opened again.
      await _push(tester, f, matched.copyWithVersion(3));
      expect(f.state.battleToOpen, isNull);
      expect(f.state.notices, hasLength(1));
    });

    fakeTimersTest('NotificationBattleOpened for another id keeps the request', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(
        tester,
        f,
        rematch(
          'b1',
          status: RematchStatus.matched,
          battleId: 'new1',
          version: 2,
        ),
      );

      f.bloc.add(const NotificationBattleOpened('other'));
      await _flush(tester);

      expect(f.state.battleToOpen, 'new1');
    });

    fakeTimersTest('visible prompt expires locally, then lingers 4 s silently', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));

      await _advance(tester, f, const Duration(seconds: 60));
      expect(_item(f).isExpired, isTrue);
      expect(f.state.prompts, hasLength(1));
      expect(f.state.notices, isEmpty);

      await _advance(tester, f, const Duration(seconds: 3));
      expect(f.state.items, hasLength(1));

      await _advance(tester, f, const Duration(seconds: 1));
      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
    });

    fakeTimersTest('hidden prompt expiry removes it with an expired notice', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.bloc.add(const NotificationHidden(_id));
      await _flush(tester);
      expect(f.state.hiddenCount, 1);

      await _advance(tester, f, const Duration(seconds: 60));

      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.expired);
    });

    fakeTimersTest('outgoing expiry gives an expired notice', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));

      await _advance(tester, f, const Duration(seconds: 60));

      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.expired);
    });

    fakeTimersTest('server EXPIRED on a visible prompt marks it expired', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));

      await _push(
        tester,
        f,
        rematch('b1', status: RematchStatus.expired, version: 2),
      );

      expect(_item(f).isExpired, isTrue);
      expect(f.state.notices, isEmpty);
    });

    fakeTimersTest('a waiting rematch already past its deadline is not shown', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);

      await _push(
        tester,
        f,
        rematch('b1', expiresAt: testNow.subtract(const Duration(seconds: 1))),
      );

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
    });

    fakeTimersTest('CANCELLED incoming gives a cancelled notice', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));

      await _push(
        tester,
        f,
        rematch('b1', status: RematchStatus.cancelled, version: 2),
      );

      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.cancelled);
    });

    fakeTimersTest('CANCELLED outgoing gives a declined notice with the name', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));

      await _push(
        tester,
        f,
        rematch(
          'b1',
          status: RematchStatus.cancelled,
          requestedBy: <String>[testMeId],
          version: 2,
        ),
      );

      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.declined);
      expect(f.state.notices.single.playerNickname, testNickname);
    });

    fakeTimersTest(
      'own Decline cancels, removes, and the CANCELLED push is silent',
      (FakeTimers tester) async {
        final NotificationFixture f = await _started(tester);
        await _push(tester, f, rematch('b1'));

        f.bloc.add(const NotificationDeclineRequested(_id));
        await _flush(tester);

        expect(f.results.cancelCalls, <String>['b1']);
        expect(f.state.items, isEmpty);
        expect(f.state.notices, isEmpty);

        await _push(
          tester,
          f,
          rematch('b1', status: RematchStatus.cancelled, version: 2),
        );
        expect(f.state.notices, isEmpty);
      },
    );

    fakeTimersTest('a CANCELLED push during the Decline request gives no notice', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      final Completer<Either<Failure, Unit>> pending =
          Completer<Either<Failure, Unit>>();
      f.results.onCancel = (_) => pending.future;

      f.bloc.add(const NotificationDeclineRequested(_id));
      await _flush(tester);
      expect(_item(f).action?.status, NotificationActionStatus.declining);

      await _push(
        tester,
        f,
        rematch('b1', status: RematchStatus.cancelled, version: 2),
      );
      pending.complete(const Right(unit));
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
    });

    fakeTimersTest('a failed Decline keeps the item with a failed action', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onCancel = (_) async => const Left(ConnectionFailure());

      f.bloc.add(const NotificationDeclineRequested(_id));
      await _flush(tester);

      expect(_item(f).action?.status, NotificationActionStatus.failed);
      expect(_item(f).action?.failure, const ConnectionFailure());

      // The retry is possible again and does not stay silent on failure.
      f.results.onCancel = (_) async => const Right(unit);
      f.bloc.add(const NotificationDeclineRequested(_id));
      await _flush(tester);
      expect(f.state.items, isEmpty);
    });

    fakeTimersTest('Accept calls requestRematch and applies MATCHED', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (String id) async => Right(
        rematch(
          id,
          status: RematchStatus.matched,
          requestedBy: <String>[testMeId, testOpponentId],
          version: 2,
          battleId: 'new1',
        ),
      );

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(f.results.requestCalls, <String>['b1']);
      expect(f.state.items, isEmpty);
      expect(f.state.battleToOpen, 'new1');
      expect(f.state.notices.single.type, NotificationNoticeType.accepted);
    });

    fakeTimersTest('Accept answered with waiting turns the card into outgoing', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (String id) async => Right(
        rematch(
          id,
          requestedBy: <String>[testOpponentId, testMeId],
          version: 2,
        ),
      );

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(_item(f).isPrompt, isFalse);
      expect(_item(f).action, isNull);
    });

    fakeTimersTest('Accept with REMATCH_EXPIRED takes the expired path', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (_) async =>
          Left(apiFailure(ApiErrorCodes.rematchExpired));

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(_item(f).isExpired, isTrue);
      expect(_item(f).action, isNull);
      await _advance(tester, f, NotificationBloc.expiredLinger);
      expect(f.state.items, isEmpty);
    });

    fakeTimersTest('Accept with REMATCH_NOT_ALLOWED removes it as cancelled', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (_) async =>
          Left(apiFailure(ApiErrorCodes.rematchNotAllowed, status: 403));

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.cancelled);
    });

    fakeTimersTest('Accept with ACTIVITY_CONFLICT sets busy and a failed action', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (_) async =>
          Left(apiFailure(ApiErrorCodes.activityConflict));

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(f.state.isBusy, isTrue);
      expect(_item(f).action?.status, NotificationActionStatus.failed);
    });

    fakeTimersTest('Accept with another failure keeps it pending and failed', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      f.results.onRequest = (_) async => const Left(TimeoutFailure());

      f.bloc.add(const NotificationAcceptRequested(_id));
      await _flush(tester);

      expect(f.state.isBusy, isFalse);
      expect(_item(f).action?.status, NotificationActionStatus.failed);
      expect(_item(f).isPrompt, isTrue);
    });

    fakeTimersTest('actions are ignored while one is in flight', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      final Completer<Either<Failure, RematchEntity>> pending =
          Completer<Either<Failure, RematchEntity>>();
      f.results.onRequest = (_) => pending.future;

      f.bloc
        ..add(const NotificationAcceptRequested(_id))
        ..add(const NotificationAcceptRequested(_id))
        ..add(const NotificationDeclineRequested(_id));
      await _flush(tester);

      expect(f.results.requestCalls, hasLength(1));
      expect(f.results.cancelCalls, isEmpty);
      expect(_item(f).action?.status, NotificationActionStatus.accepting);
    });

    fakeTimersTest('actions on unknown, outgoing or expired items are ignored', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));

      f.bloc
        ..add(const NotificationAcceptRequested('rematch:nope'))
        ..add(const NotificationAcceptRequested(_id))
        ..add(const NotificationDeclineRequested(_id));
      await _flush(tester);

      expect(f.results.requestCalls, isEmpty);
      expect(f.results.cancelCalls, isEmpty);
    });

    fakeTimersTest('Hidden hides the prompt, HiddenShown restores it', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      await _push(tester, f, rematch('b2'));

      f.bloc.add(const NotificationHidden(_id));
      await _flush(tester);
      expect(f.state.prompts, hasLength(1));
      expect(f.state.hiddenCount, 1);

      f.bloc.add(const NotificationHiddenShown());
      await _flush(tester);
      expect(f.state.prompts, hasLength(2));
      expect(f.state.hiddenCount, 0);
    });

    fakeTimersTest('hiding an outgoing item does nothing', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1', requestedBy: <String>[testMeId]));

      f.bloc.add(const NotificationHidden(_id));
      await _flush(tester);

      expect(_item(f).isHidden, isFalse);
    });

    fakeTimersTest('prompts are sorted by deadline', (FakeTimers tester) async {
      final NotificationFixture f = await _started(tester);
      await _push(
        tester,
        f,
        rematch('late', expiresAt: testNow.add(const Duration(seconds: 50))),
      );
      await _push(
        tester,
        f,
        rematch('soon', expiresAt: testNow.add(const Duration(seconds: 10))),
      );

      expect(
        f.state.prompts.map((NotificationItem i) => i.resourceId),
        <String>['soon', 'late'],
      );
    });

    fakeTimersTest('activity sets isBusy and a failed read keeps the value', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      expect(f.state.isBusy, isFalse);

      f.account.onGetActivity = () async => const Right(busyActivity);
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      expect(f.state.isBusy, isTrue);

      f.account.onGetActivity = () async => const Left(ConnectionFailure());
      f.bloc.add(const NotificationActivityRefreshRequested());
      await _flush(tester);
      expect(f.state.isBusy, isTrue);
    });

    fakeTimersTest('a new prompt re-reads the activity', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      final int before = f.account.activityCalls;

      await _push(tester, f, rematch('b1'));

      expect(f.account.activityCalls, before + 1);
    });

    fakeTimersTest('connection state follows the stream', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      // The use case yields the current (connected) status first.
      expect(f.state.isConnected, isTrue);

      f.connection.changes.add(RealtimeStatus.disconnected);
      await _flush(tester);
      expect(f.state.isConnected, isFalse);

      f.connection.changes.add(RealtimeStatus.connected);
      await _flush(tester);
      expect(f.state.isConnected, isTrue);
    });

    fakeTimersTest('reconnect re-reads known waiting items', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      f.connection.changes.add(RealtimeStatus.connected);
      await _flush(tester);
      await _push(tester, f, rematch('b1'));
      await _push(tester, f, rematch('b2'));
      f.results.onGetRematch = (String id) async => Right(
        id == 'b1'
            ? rematch(id, status: RematchStatus.cancelled, version: 2)
            : null,
      );

      f.connection.changes.add(RealtimeStatus.disconnected);
      await _flush(tester);
      f.connection.changes.add(RealtimeStatus.connected);
      await _flush(tester);

      expect(f.results.getRematchCalls.toSet(), <String>{'b1', 'b2'});
      // b1 is cancelled by the server, b2 is gone: both dropped.
      expect(f.state.items, isEmpty);
      expect(f.state.notices.single.type, NotificationNoticeType.cancelled);
    });

    fakeTimersTest('the first connected status does not trigger recovery', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));

      f.connection.changes.add(RealtimeStatus.connected);
      await _flush(tester);

      expect(f.results.getRematchCalls, isEmpty);
    });

    fakeTimersTest('sign-out clears everything', (FakeTimers tester) async {
      final NotificationFixture f = await _started(tester);
      await _push(tester, f, rematch('b1'));
      await _push(
        tester,
        f,
        rematch('b2', status: RematchStatus.matched, battleId: 'n', version: 2),
      );
      expect(f.state.items, isNotEmpty);

      f.auth.changes.add(false);
      await _flush(tester);

      expect(f.state.items, isEmpty);
      expect(f.state.notices, isEmpty);
      expect(f.state.battleToOpen, isNull);

      // Nothing is ingested while signed out and no timer fires.
      await _push(tester, f, rematch('b3'));
      await _advance(tester, f, const Duration(seconds: 90));
      expect(f.state.items, isEmpty);
    });

    test(
      'closing while Accept is in flight neither throws nor emits',
      () async {
        final NotificationFixture f = NotificationFixture();
        f.bloc.add(const NotificationStarted());
        await _settle();
        f.results.rematches.add(rematch('b1'));
        await _settle();
        final Completer<Either<Failure, RematchEntity>> pending =
            Completer<Either<Failure, RematchEntity>>();
        f.results.onRequest = (_) => pending.future;
        f.bloc.add(const NotificationAcceptRequested(_id));
        await _settle();
        expect(_item(f).action?.status, NotificationActionStatus.accepting);

        final List<NotificationState> emitted = <NotificationState>[];
        final StreamSubscription<NotificationState> sub = f.bloc.stream.listen(
          emitted.add,
        );
        final Future<void> closing = f.bloc.close();
        await _settle();
        pending.complete(
          Right(
            rematch(
              'b1',
              status: RematchStatus.matched,
              battleId: 'n',
              version: 2,
            ),
          ),
        );
        await closing;
        await sub.cancel();

        expect(emitted, isEmpty);
        expect(f.bloc.isClosed, isTrue);
        f.dispose();
      },
    );

    test('closing during enrichment neither throws nor emits', () async {
      final NotificationFixture f = NotificationFixture();
      f.bloc.add(const NotificationStarted());
      await _settle();
      final Completer<Either<Failure, BattleResultEntity>> pending =
          Completer<Either<Failure, BattleResultEntity>>();
      f.results.onGetResult = (_) => pending.future;
      f.results.rematches.add(rematch('b1'));
      await _settle();

      final List<NotificationState> emitted = <NotificationState>[];
      final StreamSubscription<NotificationState> sub = f.bloc.stream.listen(
        emitted.add,
      );
      final Future<void> closing = f.bloc.close();
      await _settle();
      pending.complete(Right(battleResult('b1')));
      await closing;
      await sub.cancel();

      expect(emitted, isEmpty);
      expect(f.bloc.isClosed, isTrue);
      f.dispose();
    });

    fakeTimersTest('notices are consumed one by one with unique ids', (
      FakeTimers tester,
    ) async {
      final NotificationFixture f = await _started(tester);
      for (final String id in <String>['b1', 'b2']) {
        await _push(tester, f, rematch(id));
        await _push(
          tester,
          f,
          rematch(id, status: RematchStatus.cancelled, version: 2),
        );
      }
      expect(f.state.notices, hasLength(2));
      final String first = f.state.notices.first.id;
      expect(first, isNot(f.state.notices.last.id));

      f.bloc.add(NotificationNoticeShown(first));
      await _flush(tester);

      expect(f.state.notices, hasLength(1));
      expect(f.state.notices.single.id, isNot(first));
    });
  });
}

extension on RematchEntity {
  RematchEntity copyWithVersion(int version) => RematchEntity(
    sourceBattleId: sourceBattleId,
    status: status,
    requestedBy: requestedBy,
    expiresAt: expiresAt,
    battleId: battleId,
    version: version,
  );
}
