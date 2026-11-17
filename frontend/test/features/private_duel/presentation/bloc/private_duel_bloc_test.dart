import 'dart:async';

import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';
import 'package:skill_battles/features/private_duel/domain/repository/private_duel_repository.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/cancel_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/create_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/get_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/watch_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/presentation/bloc/private_duel_bloc/private_duel_bloc.dart';

import '../../../../helpers/notification_fakes.dart';

const PublicPlayerEntity _guest = PublicPlayerEntity(
  id: 'guest',
  nickname: 'Guest',
  isPro: false,
);

const ApiFailure _alreadyMatched = ApiFailure(
  statusCode: 409,
  errorCode: ApiErrorCodes.matchAlreadyFound,
  message: 'A battle has already been created.',
);

DuelEntity _duel({
  DuelStatus status = DuelStatus.waiting,
  PublicPlayerEntity? guest,
  int version = 1,
}) => DuelEntity(
  id: 'duel-1',
  code: 'ABC234',
  disciplineCode: 'SAT_MATH',
  status: status,
  host: const PublicPlayerEntity(id: 'host', nickname: 'Host', isPro: false),
  guest: guest,
  expiresAt: DateTime.utc(2026, 11, 15, 12, 10),
  battleId: status == DuelStatus.matched ? 'battle-1' : null,
  version: version,
);

final class _PrivateDuelRepository implements PrivateDuelRepository {
  DuelEntity duel = _duel();
  Future<Either<Failure, DuelEntity>> Function()? onCreate;
  Future<Either<Failure, DuelEntity>> Function()? onGet;
  Future<Either<Failure, Unit>> Function()? onCancel;

  final List<String> createCalls = <String>[];
  final List<String> getCalls = <String>[];
  final List<String> cancelCalls = <String>[];
  final List<String> watchCalls = <String>[];
  final StreamController<DuelEntity> changes =
      StreamController<DuelEntity>.broadcast();

  @override
  Future<Either<Failure, DuelEntity>> createDuel(String disciplineCode) {
    createCalls.add(disciplineCode);
    return onCreate?.call() ?? Future.value(Right(duel));
  }

  @override
  Future<Either<Failure, DuelEntity>> getDuel(String duelId) {
    getCalls.add(duelId);
    return onGet?.call() ?? Future.value(Right(duel));
  }

  @override
  Future<Either<Failure, Unit>> cancelDuel(String duelId) {
    cancelCalls.add(duelId);
    return onCancel?.call() ?? Future.value(const Right(unit));
  }

  @override
  Stream<DuelEntity> watchDuel(String duelId) {
    watchCalls.add(duelId);
    return changes.stream;
  }

  @override
  Future<Either<Failure, DuelEntity>> joinDuel(String code) =>
      throw UnimplementedError();
}

Future<void> _settle() async {
  for (int i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _PrivateDuelRepository repository;
  late FakeConnectionRepository connection;
  late PrivateDuelBloc bloc;

  setUp(() {
    repository = _PrivateDuelRepository();
    connection = FakeConnectionRepository(status: RealtimeStatus.disconnected);
    bloc = PrivateDuelBloc(
      createDuel: CreateDuelUsecase(repository),
      getDuel: GetDuelUsecase(repository),
      cancelDuel: CancelDuelUsecase(repository),
      watchDuel: WatchDuelUsecase(repository),
      watchConnection: WatchConnectionUsecase(connection),
    );
  });

  tearDown(() async {
    if (!bloc.isClosed) await bloc.close();
    await repository.changes.close();
    await connection.changes.close();
  });

  Future<void> start() async {
    bloc.add(const PrivateDuelStarted(disciplineCode: 'SAT_MATH'));
    await _settle();
  }

  group('PrivateDuelBloc screen exit', () {
    test('cancels an empty waiting room once and stops following it', () async {
      await start();
      final int reads = repository.getCalls.length;

      await bloc.close();
      repository.changes.add(_duel(status: DuelStatus.matched, guest: _guest));
      connection.changes.add(RealtimeStatus.connected);
      await _settle();

      expect(repository.cancelCalls, <String>['duel-1']);
      expect(repository.getCalls, hasLength(reads));
      expect(repository.changes.hasListener, isFalse);
      expect(connection.changes.hasListener, isFalse);
      expect(bloc.isClosed, isTrue);
    });

    test('repeated exits share the pending room cancellation', () async {
      final Completer<Either<Failure, Unit>> response =
          Completer<Either<Failure, Unit>>();
      repository.onCancel = () => response.future;
      await start();

      final Future<void> first = bloc.close();
      final Future<void> second = bloc.close();
      await _settle();
      expect(repository.cancelCalls, <String>['duel-1']);
      response.complete(const Right(unit));
      await Future.wait(<Future<void>>[first, second]);
      await bloc.close();

      expect(repository.cancelCalls, <String>['duel-1']);
      expect(bloc.isClosed, isTrue);
    });

    test('preserves a room after a guest joins through realtime', () async {
      await start();
      repository.changes.add(
        _duel(status: DuelStatus.matched, guest: _guest, version: 2),
      );
      await _settle();
      expect(bloc.stateValue.battleId, 'battle-1');

      await bloc.close();

      expect(repository.cancelCalls, isEmpty);
    });

    test(
      'preserves a waiting snapshot that already contains a guest',
      () async {
        repository.duel = _duel(guest: _guest);
        await start();

        await bloc.close();

        expect(repository.cancelCalls, isEmpty);
      },
    );

    for (final DuelStatus status in <DuelStatus>[
      DuelStatus.matched,
      DuelStatus.expired,
      DuelStatus.cancelled,
    ]) {
      test('does not cancel a ${status.name} room', () async {
        repository.duel = _duel(status: status);
        await start();

        await bloc.close();

        expect(repository.cancelCalls, isEmpty);
      });
    }

    test('does not cancel when no room was opened', () async {
      await bloc.close();

      expect(repository.cancelCalls, isEmpty);
      expect(repository.createCalls, isEmpty);
    });

    test('does not cancel after room creation fails', () async {
      repository.onCreate = () async => const Left(ConnectionFailure());
      await start();
      expect(bloc.stateValue.loadStatus, LoadStatus.failure);

      await bloc.close();

      expect(repository.cancelCalls, isEmpty);
    });

    for (final Failure failure in <Failure>[
      _alreadyMatched,
      const TimeoutFailure(),
    ]) {
      test(
        'closes safely when cancellation returns ${failure.runtimeType}',
        () async {
          repository.onCancel = () async => Left(failure);
          await start();
          final PrivateDuelState state = bloc.stateValue;

          await bloc.close();

          expect(repository.cancelCalls, <String>['duel-1']);
          expect(bloc.stateValue, state);
          expect(bloc.isClosed, isTrue);
        },
      );
    }
  });

  group('PrivateDuelBloc exit during a room request', () {
    test(
      'cancels a room created after exit without emitting or following it',
      () async {
        final Completer<Either<Failure, DuelEntity>> response =
            Completer<Either<Failure, DuelEntity>>();
        repository.onCreate = () => response.future;
        await start();
        expect(repository.createCalls, <String>['SAT_MATH']);
        final List<PrivateDuelState> afterExit = <PrivateDuelState>[];
        final StreamSubscription<PrivateDuelState> subscription = bloc.stream
            .listen(afterExit.add);

        final Future<void> closing = bloc.close();
        await _settle();
        response.complete(Right(_duel()));
        await closing;
        await _settle();
        await subscription.cancel();

        expect(repository.cancelCalls, <String>['duel-1']);
        expect(repository.watchCalls, isEmpty);
        expect(repository.getCalls, isEmpty);
        expect(afterExit, isEmpty);
      },
    );

    test(
      'preserves a matched room returned by a late create response',
      () async {
        final Completer<Either<Failure, DuelEntity>> response =
            Completer<Either<Failure, DuelEntity>>();
        repository.onCreate = () => response.future;
        await start();

        final Future<void> closing = bloc.close();
        await _settle();
        response.complete(
          Right(_duel(status: DuelStatus.matched, guest: _guest)),
        );
        await closing;
        await _settle();

        expect(repository.cancelCalls, isEmpty);
        expect(repository.watchCalls, isEmpty);
        expect(repository.getCalls, isEmpty);
      },
    );

    test(
      'cancels a resumed empty room returned after exit without emitting',
      () async {
        final Completer<Either<Failure, DuelEntity>> response =
            Completer<Either<Failure, DuelEntity>>();
        repository.onGet = () => response.future;
        bloc.add(const PrivateDuelStarted(duelId: 'duel-1'));
        await _settle();
        expect(repository.getCalls, <String>['duel-1']);
        final List<PrivateDuelState> afterExit = <PrivateDuelState>[];
        final StreamSubscription<PrivateDuelState> subscription = bloc.stream
            .listen(afterExit.add);

        final Future<void> closing = bloc.close();
        await _settle();
        response.complete(Right(_duel()));
        await closing;
        await _settle();
        await subscription.cancel();

        expect(repository.cancelCalls, <String>['duel-1']);
        expect(repository.getCalls, <String>['duel-1']);
        expect(repository.changes.hasListener, isFalse);
        expect(connection.changes.hasListener, isFalse);
        expect(afterExit, isEmpty);
      },
    );

    test(
      'preserves a newer realtime match over a late resume response',
      () async {
        final Completer<Either<Failure, DuelEntity>> response =
            Completer<Either<Failure, DuelEntity>>();
        repository.onGet = () => response.future;
        bloc.add(const PrivateDuelStarted(duelId: 'duel-1'));
        await _settle();
        expect(repository.getCalls, <String>['duel-1']);
        final DuelEntity matched = _duel(
          status: DuelStatus.matched,
          guest: _guest,
          version: 2,
        );
        repository.changes.add(matched);
        await _settle();
        expect(bloc.stateValue.duel, matched);

        final Future<void> closing = bloc.close();
        await _settle();
        response.complete(Right(_duel()));
        await closing;
        await _settle();

        expect(repository.cancelCalls, isEmpty);
        expect(bloc.stateValue.duel, matched);
        expect(bloc.stateValue.battleId, 'battle-1');
      },
    );
  });

  group('PrivateDuelBloc explicit cancellation and exit', () {
    test(
      'does not repeat a successful explicit cancellation on exit',
      () async {
        await start();
        bloc.add(const PrivateDuelCancelRequested());
        await _settle();
        expect(bloc.stateValue.cancelStatus, LoadStatus.success);

        await bloc.close();

        expect(repository.cancelCalls, <String>['duel-1']);
      },
    );

    test('shares an in-flight explicit cancellation when leaving', () async {
      final Completer<Either<Failure, Unit>> response =
          Completer<Either<Failure, Unit>>();
      repository.onCancel = () => response.future;
      await start();
      bloc.add(const PrivateDuelCancelRequested());
      await _settle();
      expect(repository.cancelCalls, <String>['duel-1']);
      final PrivateDuelState state = bloc.stateValue;

      final Future<void> closing = bloc.close();
      await _settle();
      response.complete(const Right(unit));
      await closing;
      await _settle();

      expect(repository.cancelCalls, <String>['duel-1']);
      expect(bloc.stateValue, state);
    });

    test('preserves a match found during explicit cancellation', () async {
      await start();
      repository.onCancel = () async => const Left(_alreadyMatched);
      repository.duel = _duel(
        status: DuelStatus.matched,
        guest: _guest,
        version: 2,
      );
      bloc.add(const PrivateDuelCancelRequested());
      await _settle();
      expect(bloc.stateValue.battleId, 'battle-1');
      expect(bloc.stateValue.cancelFailure, isNull);

      await bloc.close();

      expect(repository.cancelCalls, <String>['duel-1']);
    });
  });
}
