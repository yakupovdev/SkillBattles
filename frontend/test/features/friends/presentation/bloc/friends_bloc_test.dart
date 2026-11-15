import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_status.dart';
import 'package:skill_battles/features/friends/domain/entity/send_friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/cancel_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_code_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';

import '../../../../helpers/friends_fakes.dart';
import '../../../../helpers/notification_fakes.dart';

Future<void> _settle() async {
  for (int i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _Fixture {
  _Fixture() {
    bloc = FriendsBloc(
      getFriendCode: GetFriendCodeUsecase(repo),
      getFriends: GetFriendsUsecase(repo),
      getFriendRequests: GetFriendRequestsUsecase(repo),
      sendFriendRequest: SendFriendRequestUsecase(repo),
      acceptFriendRequest: AcceptFriendRequestUsecase(repo),
      declineFriendRequest: DeclineFriendRequestUsecase(repo),
      cancelFriendRequest: CancelFriendRequestUsecase(repo),
      removeFriend: RemoveFriendUsecase(repo),
      watchFriendshipChanges: WatchFriendshipChangesUsecase(repo),
      watchConnection: WatchConnectionUsecase(connection),
      pageSize: 2,
    );
  }

  final ScriptedFriendsRepository repo = ScriptedFriendsRepository();
  final FakeConnectionRepository connection = FakeConnectionRepository();
  late final FriendsBloc bloc;

  FriendsState get state => bloc.state;

  Future<void> start() async {
    bloc.add(const FriendsStarted());
    await _settle();
  }

  Future<void> send(FriendsEvent event) async {
    bloc.add(event);
    await _settle();
  }

  Future<void> dispose() async {
    await bloc.close();
    await repo.dispose();
    await connection.changes.close();
  }

  int friendsCalls() => repo.friendsCalls.length;

  int requestCalls(FriendRequestDirection direction) =>
      repo.requestsCalls.where((p) => p.direction == direction).length;
}

PublicPlayerEntity _player(int i) =>
    PublicPlayerEntity(id: 'u$i', nickname: 'Friend $i', isPro: false);

/// A server holding [total] friends, paged like the real one.
Future<Either<Failure, FriendsPageEntity>> _serve(
  FriendsPageParamsEntity p,
  int total,
) async {
  final int pages = (total / p.size).ceil();
  final int from = p.page * p.size;
  final int to = (from + p.size).clamp(from, total < from ? from : total);
  return ok(
    friendsPage(
      <FriendListItemEntity>[
        for (int i = from; i < to; i++) friendItem('rel$i', _player(i)),
      ],
      page: p.page,
      totalPages: pages,
      totalElements: total,
    ),
  );
}

void main() {
  late _Fixture f;

  setUp(() => f = _Fixture());
  tearDown(() => f.dispose());

  group('loading', () {
    test('starts with an initial state', () {
      expect(f.state, const FriendsState());
    });

    test('FriendsStarted loads the code and page 0 of three lists', () async {
      f.repo.onGetFriends = (p) => _serve(p, 3);
      f.repo.onGetFriendRequests = (p) async => ok(
        requestsPage(<RelationshipEntity>[
          relationship(
            'r-${p.direction.name}',
            incoming: p.direction == FriendRequestDirection.incoming,
          ),
        ]),
      );

      await f.start();

      expect(f.state.codeStatus, LoadStatus.success);
      expect(f.state.code!.code, 'ABCD2345EFGH');
      expect(f.state.friends.loadStatus, LoadStatus.success);
      expect(f.state.friends.items, hasLength(2));
      expect(f.state.friends.hasNext, isTrue);
      expect(f.state.friends.hasPrevious, isFalse);
      expect(f.state.friends.totalElements, 3);
      expect(f.state.incoming.items.single.id, 'r-incoming');
      expect(f.state.outgoing.items.single.id, 'r-outgoing');
      expect(
        f.repo.friendsCalls.single,
        const FriendsPageParamsEntity(size: 2),
      );
    });

    test('a failed list keeps the others; retry reloads only it', () async {
      f.repo.onGetFriends = (p) async => failed(const ConnectionFailure());
      await f.start();

      expect(f.state.friends.loadStatus, LoadStatus.failure);
      expect(f.state.friends.failure, const ConnectionFailure());
      expect(f.state.incoming.loadStatus, LoadStatus.success);
      expect(f.state.codeStatus, LoadStatus.success);

      final int incomingCalls = f.requestCalls(FriendRequestDirection.incoming);
      f.repo.onGetFriends = (p) => _serve(p, 1);
      await f.send(const FriendsListRetryRequested(FriendsList.friends));

      expect(f.state.friends.loadStatus, LoadStatus.success);
      expect(f.state.friends.failure, isNull);
      expect(f.requestCalls(FriendRequestDirection.incoming), incomingCalls);
    });

    test('refresh retries the code only when it failed', () async {
      f.repo.onGetFriendCode = () async => failed(const TimeoutFailure());
      await f.start();
      expect(f.state.codeStatus, LoadStatus.failure);
      expect(f.state.codeFailure, const TimeoutFailure());

      f.repo.onGetFriendCode = () async =>
          ok(const FriendCodeEntity(code: 'ZZZZ2222YYYY'));
      await f.send(const FriendsRefreshRequested());
      expect(f.state.codeStatus, LoadStatus.success);
      expect(f.state.codeFailure, isNull);

      await f.send(const FriendsRefreshRequested());
      expect(f.repo.codeCalls, 2);
    });

    test('a refresh with items keeps them visible while loading', () async {
      f.repo.onGetFriends = (p) => _serve(p, 2);
      await f.start();
      final Completer<void> gate = Completer<void>();
      f.repo.onGetFriends = (p) async {
        await gate.future;
        return _serve(p, 2);
      };

      f.bloc.add(const FriendsRefreshRequested());
      await _settle();

      expect(f.state.friends.loadStatus, LoadStatus.loading);
      expect(f.state.friends.items, hasLength(2));
      gate.complete();
      await _settle();
      expect(f.state.friends.loadStatus, LoadStatus.success);
    });
  });

  group('paging', () {
    test('FriendsPageRequested replaces the items and keeps pageStatus '
        'separate', () async {
      f.repo.onGetFriends = (p) => _serve(p, 5);
      await f.start();
      final List<FriendsState> states = <FriendsState>[];
      final StreamSubscription<FriendsState> sub = f.bloc.stream.listen(
        states.add,
      );

      await f.send(const FriendsPageRequested(FriendsList.friends, 1));
      await sub.cancel();

      expect(states.map((FriendsState s) => s.friends.pageStatus), <LoadStatus>[
        LoadStatus.loading,
        LoadStatus.success,
      ]);
      expect(states.first.friends.items.first.relationshipId, 'rel0');
      expect(f.state.friends.items.map((i) => i.relationshipId), <String>[
        'rel2',
        'rel3',
      ]);
      expect(f.state.friends.page!.page, 1);
      expect(f.state.friends.loadStatus, LoadStatus.success);
      expect(f.state.friends.hasPrevious, isTrue);
      expect(f.state.friends.hasNext, isTrue);
    });

    test('a failed page change keeps the current page and reports its own '
        'failure', () async {
      f.repo.onGetFriends = (p) => _serve(p, 5);
      await f.start();
      f.repo.onGetFriends = (p) async => failed(const ConnectionFailure());

      await f.send(const FriendsPageRequested(FriendsList.friends, 1));

      expect(f.state.friends.pageStatus, LoadStatus.failure);
      expect(f.state.friends.pageFailure, const ConnectionFailure());
      expect(f.state.friends.loadStatus, LoadStatus.success);
      expect(f.state.friends.items.first.relationshipId, 'rel0');
    });

    test(
      'a refresh clears a previous page error and loads the target page',
      () async {
        f.repo.onGetFriends = (p) => _serve(p, 5);
        await f.start();
        f.repo.onGetFriends = (p) async => failed(const ConnectionFailure());
        await f.send(const FriendsPageRequested(FriendsList.friends, 1));
        expect(f.state.friends.pageFailure, const ConnectionFailure());

        f.repo.onGetFriends = (p) => _serve(p, 5);
        await f.send(const FriendsRefreshRequested());

        expect(f.state.friends.loadStatus, LoadStatus.success);
        expect(f.state.friends.pageStatus, LoadStatus.initial);
        expect(f.state.friends.pageFailure, isNull);
        expect(f.state.friends.page!.page, 1);
      },
    );

    test('out-of-range pages are clamped to the known pages', () async {
      f.repo.onGetFriends = (p) => _serve(p, 5);
      await f.start();

      await f.send(const FriendsPageRequested(FriendsList.friends, 9));
      expect(f.repo.friendsCalls.last.page, 2);
      expect(f.state.friends.page!.page, 2);

      await f.send(const FriendsPageRequested(FriendsList.friends, -3));
      expect(f.repo.friendsCalls.last.page, 0);
    });

    test('the shown page is ignored, and a request while the list loads '
        'too', () async {
      f.repo.onGetFriends = (p) => _serve(p, 5);
      await f.start();
      final int calls = f.friendsCalls();

      await f.send(const FriendsPageRequested(FriendsList.friends, 0));
      expect(f.friendsCalls(), calls);

      final Completer<void> gate = Completer<void>();
      f.repo.onGetFriends = (p) async {
        await gate.future;
        return _serve(p, 5);
      };
      f.bloc.add(const FriendsPageRequested(FriendsList.friends, 1));
      await _settle();
      f.bloc.add(const FriendsPageRequested(FriendsList.friends, 2));
      await _settle();
      expect(f.friendsCalls(), calls + 1);
      gate.complete();
      await _settle();
      expect(f.state.friends.page!.page, 1);
    });

    test('latest wins: a refresh supersedes a running page change', () async {
      f.repo.onGetFriends = (p) => _serve(p, 6);
      await f.start();
      final Completer<Either<Failure, FriendsPageEntity>> slow =
          Completer<Either<Failure, FriendsPageEntity>>();
      int call = 0;
      f.repo.onGetFriends = (p) {
        call++;
        return call == 1 ? slow.future : _serve(p, 6);
      };

      f.bloc.add(const FriendsPageRequested(FriendsList.friends, 1));
      await _settle();
      expect(f.state.friends.pageStatus, LoadStatus.loading);
      await f.send(const FriendsRefreshRequested());

      // The refresh loads the requested page 1 and ends the page change.
      expect(f.state.friends.pageStatus, LoadStatus.initial);
      expect(f.state.friends.page!.page, 1);

      slow.complete(
        ok(
          friendsPage(<FriendListItemEntity>[friendItem('stale', _player(99))]),
        ),
      );
      await _settle();

      expect(f.state.friends.items.map((i) => i.relationshipId), <String>[
        'rel2',
        'rel3',
      ]);
    });

    test('latest wins: of two refreshes the second answer survives', () async {
      f.repo.onGetFriends = (p) => _serve(p, 2);
      await f.start();
      final Completer<void> first = Completer<void>();
      int call = 0;
      f.repo.onGetFriends = (p) async {
        if (++call == 1) {
          await first.future;
          return ok(
            friendsPage(<FriendListItemEntity>[friendItem('old', _player(90))]),
          );
        }
        return ok(
          friendsPage(<FriendListItemEntity>[friendItem('new', _player(91))]),
        );
      };

      f.bloc.add(const FriendsRefreshRequested());
      await _settle();
      f.bloc.add(const FriendsRefreshRequested());
      await _settle();
      first.complete();
      await _settle();

      expect(f.state.friends.items.single.relationshipId, 'new');
    });

    test('an invalidation refetches the CURRENT page', () async {
      f.repo.onGetFriends = (p) => _serve(p, 5);
      await f.start();
      await f.send(const FriendsPageRequested(FriendsList.friends, 1));
      final int calls = f.friendsCalls();

      f.repo.friendships.add(
        relationship('x', status: RelationshipStatus.accepted, version: 2),
      );
      await _settle();

      expect(f.friendsCalls(), calls + 1);
      expect(f.repo.friendsCalls.last.page, 1);
      expect(f.state.friends.page!.page, 1);
    });

    test('a current page past the end falls back to the last page', () async {
      f.repo.onGetFriends = (p) => _serve(p, 3);
      await f.start();
      await f.send(const FriendsPageRequested(FriendsList.friends, 1));
      expect(f.state.friends.page!.page, 1);

      // The only row of the last page was removed on the server.
      f.repo.onGetFriends = (p) => _serve(p, 2);
      f.repo.friendships.add(
        relationship('x', status: RelationshipStatus.removed, version: 3),
      );
      await _settle();

      expect(
        f.repo.friendsCalls
            .map((p) => p.page)
            .toList()
            .sublist(f.repo.friendsCalls.length - 2),
        <int>[1, 0],
      );
      expect(f.state.friends.page!.page, 0);
      expect(f.state.friends.items, hasLength(2));
    });
  });

  group('invalidation', () {
    test('pushes refetch only the lists they affect', () async {
      await f.start();

      Future<(int, int, int)> after(RelationshipEntity push) async {
        final int fr = f.friendsCalls();
        final int inc = f.requestCalls(FriendRequestDirection.incoming);
        final int out = f.requestCalls(FriendRequestDirection.outgoing);
        f.repo.friendships.add(push);
        await _settle();
        return (
          f.friendsCalls() - fr,
          f.requestCalls(FriendRequestDirection.incoming) - inc,
          f.requestCalls(FriendRequestDirection.outgoing) - out,
        );
      }

      expect(await after(relationship('a')), (0, 1, 0));
      expect(await after(relationship('b', incoming: false)), (0, 0, 1));
      expect(
        await after(
          relationship('c', status: RelationshipStatus.removed, version: 2),
        ),
        (1, 0, 0),
      );
      expect(
        await after(
          relationship('d', status: RelationshipStatus.accepted, version: 2),
        ),
        (1, 1, 1),
      );
    });

    test('a reconnect refetches every list', () async {
      await f.start();
      final int fr = f.friendsCalls();

      f.connection.changes
        ..add(RealtimeStatus.disconnected)
        ..add(RealtimeStatus.connected);
      await _settle();

      expect(f.friendsCalls(), fr + 1);
      expect(f.requestCalls(FriendRequestDirection.incoming), 2);
      expect(f.requestCalls(FriendRequestDirection.outgoing), 2);
    });
  });

  group('add friend', () {
    test('a malformed code is a ValidationFailure without a request', () async {
      await f.start();

      await f.send(
        const FriendRequestSubmitted(
          SendFriendRequestParamsEntity(friendCode: 'abc'),
        ),
      );

      expect(f.state.sendStatus, LoadStatus.failure);
      expect(f.state.sendFailure, isA<ValidationFailure>());
      expect(f.repo.sendCodes, isEmpty);
    });

    test('the code is normalised and success keeps the sent request', () async {
      await f.start();
      final int out = f.requestCalls(FriendRequestDirection.outgoing);
      f.repo.onSendFriendRequest = (c) async =>
          ok(relationship('new', incoming: false, other: friendBoris));

      await f.send(
        const FriendRequestSubmitted(
          SendFriendRequestParamsEntity(friendCode: ' abcd-2345-efgh '),
        ),
      );

      expect(f.repo.sendCodes, <String>['ABCD2345EFGH']);
      expect(f.state.sendStatus, LoadStatus.success);
      expect(f.state.sentRequest!.id, 'new');
      expect(f.state.sendFailure, isNull);
      expect(f.requestCalls(FriendRequestDirection.outgoing), out + 1);
    });

    test('a new submit clears the previous failure and sent request', () async {
      await f.start();
      f.repo.onSendFriendRequest = (c) async =>
          failed(apiFailure(ApiErrorCodes.friendCodeNotFound, status: 404));
      const FriendRequestSubmitted submit = FriendRequestSubmitted(
        SendFriendRequestParamsEntity(friendCode: 'ABCD2345EFGH'),
      );
      await f.send(submit);
      expect(
        f.state.sendFailure!.hasCode(ApiErrorCodes.friendCodeNotFound),
        isTrue,
      );

      f.repo.onSendFriendRequest = (c) async => ok(relationship('new'));
      await f.send(submit);
      expect(f.state.sendFailure, isNull);
      expect(f.state.sentRequest!.id, 'new');
    });

    test(
      'ALREADY_RECEIVED refetches incoming and never auto-accepts',
      () async {
        await f.start();
        final int inc = f.requestCalls(FriendRequestDirection.incoming);
        final int fr = f.friendsCalls();
        f.repo.onSendFriendRequest = (c) async =>
            failed(apiFailure(ApiErrorCodes.friendRequestAlreadyReceived));

        await f.send(
          const FriendRequestSubmitted(
            SendFriendRequestParamsEntity(friendCode: 'ABCD2345EFGH'),
          ),
        );

        expect(f.state.sendStatus, LoadStatus.failure);
        expect(f.requestCalls(FriendRequestDirection.incoming), inc + 1);
        expect(f.friendsCalls(), fr);
        expect(f.repo.acceptRequestCalls, isEmpty);
      },
    );

    test('ALREADY_EXISTS refetches the friends list', () async {
      await f.start();
      final int fr = f.friendsCalls();
      f.repo.onSendFriendRequest = (c) async =>
          failed(apiFailure(ApiErrorCodes.friendAlreadyExists));

      await f.send(
        const FriendRequestSubmitted(
          SendFriendRequestParamsEntity(friendCode: 'ABCD2345EFGH'),
        ),
      );

      expect(f.friendsCalls(), fr + 1);
    });

    test('RATE_LIMITED keeps retryAfter on the failure', () async {
      await f.start();
      f.repo.onSendFriendRequest = (c) async => failed(
        const ApiFailure(
          statusCode: 429,
          errorCode: ApiErrorCodes.rateLimited,
          message: 'slow down',
          retryAfter: Duration(seconds: 30),
        ),
      );

      await f.send(
        const FriendRequestSubmitted(
          SendFriendRequestParamsEntity(friendCode: 'ABCD2345EFGH'),
        ),
      );

      expect(
        (f.state.sendFailure! as ApiFailure).retryAfter,
        const Duration(seconds: 30),
      );
    });
  });

  group('row actions', () {
    setUp(() {
      f.repo.onGetFriendRequests = (p) async => ok(
        requestsPage(<RelationshipEntity>[
          relationship(
            'r1',
            incoming: p.direction == FriendRequestDirection.incoming,
          ),
        ]),
      );
    });

    test(
      'Accept: loading, success, and incoming + friends refetched',
      () async {
        await f.start();
        final Completer<void> gate = Completer<void>();
        f.repo.onAcceptFriendRequest = (id) async {
          await gate.future;
          return ok(
            relationship('r1', status: RelationshipStatus.accepted, version: 2),
          );
        };
        final int inc = f.requestCalls(FriendRequestDirection.incoming);
        final int fr = f.friendsCalls();

        f.bloc.add(const FriendRequestAcceptRequested('r1'));
        await _settle();
        expect(f.state.requestActions['r1']!.status, LoadStatus.loading);

        // A second tap while it runs is ignored.
        f.bloc.add(const FriendRequestAcceptRequested('r1'));
        await _settle();
        expect(f.repo.acceptRequestCalls, <String>['r1']);

        gate.complete();
        await _settle();

        expect(f.state.requestActions['r1']!.status, LoadStatus.success);
        expect(f.requestCalls(FriendRequestDirection.incoming), inc + 1);
        expect(f.friendsCalls(), fr + 1);
      },
    );

    test(
      'Accept failure is kept on the row and the list is refetched',
      () async {
        await f.start();
        f.repo.onAcceptFriendRequest = (id) async =>
            failed(apiFailure(ApiErrorCodes.friendRequestNotPending));
        final int inc = f.requestCalls(FriendRequestDirection.incoming);

        await f.send(const FriendRequestAcceptRequested('r1'));

        final FriendsItemAction action = f.state.requestActions['r1']!;
        expect(action.status, LoadStatus.failure);
        expect(
          action.failure!.hasCode(ApiErrorCodes.friendRequestNotPending),
          isTrue,
        );
        expect(f.requestCalls(FriendRequestDirection.incoming), inc + 1);
      },
    );

    test('Decline and Cancel call their use cases and refetch', () async {
      await f.start();
      f.repo.onDeclineFriendRequest = (id) async => ok(
        relationship('r1', status: RelationshipStatus.declined, version: 2),
      );
      await f.send(const FriendRequestDeclineRequested('r1'));
      expect(f.repo.declineRequestCalls, <String>['r1']);
      expect(f.state.requestActions['r1']!.status, LoadStatus.success);

      final int out = f.requestCalls(FriendRequestDirection.outgoing);
      await f.send(const FriendRequestCancelRequested('r1'));
      expect(f.repo.cancelRequestCalls, <String>['r1']);
      expect(f.requestCalls(FriendRequestDirection.outgoing), out + 1);
    });

    test('an action of a row that left the list is pruned', () async {
      // Relationship ids are globally unique: the outgoing request being
      // cancelled must not also exist in the incoming list.
      f.repo.onGetFriendRequests = (p) async => ok(
        requestsPage([
          relationship(
            p.direction == FriendRequestDirection.incoming
                ? 'incoming-r1'
                : 'r1',
            incoming: p.direction == FriendRequestDirection.incoming,
          ),
        ]),
      );
      await f.start();
      f.repo.onCancelFriendRequest = (id) async => ok(unit);
      f.repo.onGetFriendRequests = (p) async =>
          ok(requestsPage(const <RelationshipEntity>[], totalPages: 0));

      await f.send(const FriendRequestCancelRequested('r1'));

      expect(f.state.requestActions, isEmpty);
    });

    test('Remove friend uses the USER id and refetches friends', () async {
      f.repo.onGetFriends = (p) => _serve(p, 2);
      await f.start();
      final int fr = f.friendsCalls();

      await f.send(const FriendRemoveRequested('u0'));

      expect(f.repo.removeCalls, <String>['u0']);
      expect(f.state.friendActions['u0']!.status, LoadStatus.success);
      expect(f.friendsCalls(), fr + 1);
    });

    test('Remove failure is kept on the friend row', () async {
      f.repo.onGetFriends = (p) => _serve(p, 2);
      await f.start();
      f.repo.onRemoveFriend = (id) async => failed(const TimeoutFailure());

      await f.send(const FriendRemoveRequested('u0'));

      expect(f.state.friendActions['u0']!.status, LoadStatus.failure);
      expect(f.state.friendActions['u0']!.failure, const TimeoutFailure());
    });
  });

  test('closing while a command is awaited neither throws nor emits', () async {
    await f.start();
    final Completer<void> gate = Completer<void>();
    f.repo.onRemoveFriend = (id) async {
      await gate.future;
      return ok(unit);
    };
    f.bloc.add(const FriendRemoveRequested('u0'));
    await _settle();
    final List<FriendsState> emitted = <FriendsState>[];
    final StreamSubscription<FriendsState> sub = f.bloc.stream.listen(
      emitted.add,
    );

    final Future<void> closing = f.bloc.close();
    await _settle();
    gate.complete();
    await closing;
    await sub.cancel();

    expect(emitted, isEmpty);
    expect(f.bloc.isClosed, isTrue);
  });
}
