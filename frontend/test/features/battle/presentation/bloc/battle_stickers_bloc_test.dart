import 'dart:async';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_stickers_usecase.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';

const String _battle = 'b1';
const String _me = 'me';
const String _opponent = 'opp';

/// Each send waits for the next completer the test pushes, so the test
/// decides when (and in which order) answers arrive.
final class _FakeBattleRepository implements BattleRepository {
  final StreamController<IncomingStickerEntity> stickers =
      StreamController<IncomingStickerEntity>.broadcast();
  final List<SendStickerParamsEntity> sends = <SendStickerParamsEntity>[];
  final List<Completer<Either<Failure, StickerReceiptEntity>>> pending =
      <Completer<Either<Failure, StickerReceiptEntity>>>[];

  /// Completes the oldest unanswered send.
  void answer(Either<Failure, StickerReceiptEntity> result) =>
      pending.removeAt(0).complete(result);

  @override
  Future<Either<Failure, StickerReceiptEntity>> sendSticker(
    SendStickerParamsEntity params,
  ) {
    sends.add(params);
    final Completer<Either<Failure, StickerReceiptEntity>> completer =
        Completer<Either<Failure, StickerReceiptEntity>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Stream<IncomingStickerEntity> watchStickers(String battleId) =>
      stickers.stream;

  @override
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BattleSnapshotEntity>> setReady(String battleId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, AnswerReceiptEntity>> submitAnswer(
    SubmitAnswerParamsEntity params,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, BattleSnapshotEntity>> surrender(String battleId) =>
      throw UnimplementedError();

  @override
  Stream<BattleSnapshotEntity> watchBattle(String battleId) =>
      throw UnimplementedError();
}

final class _FakeConnection implements ConnectionRepository {
  final StreamController<RealtimeStatus> changes =
      StreamController<RealtimeStatus>.broadcast();

  @override
  RealtimeStatus status = RealtimeStatus.connected;

  void set(RealtimeStatus value) {
    status = value;
    changes.add(value);
  }

  @override
  Stream<RealtimeStatus> watchStatus() => changes.stream;
}

ApiFailure _api(
  String code, {
  int status = 409,
  DateTime? resetsAt,
  Duration? retryAfter,
}) => ApiFailure(
  statusCode: status,
  errorCode: code,
  message: code,
  resetsAt: resetsAt,
  retryAfter: retryAfter,
);

Future<void> _flush([int milliseconds = 5]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  late _FakeBattleRepository repository;
  late _FakeConnection connection;
  late DateTime now;
  late BattleStickersBloc bloc;

  BattleStickersBloc build({
    Duration ownBubble = const Duration(milliseconds: 200),
    Duration opponentBubble = const Duration(milliseconds: 200),
    Duration notSent = const Duration(milliseconds: 60),
    Duration retryDelay = const Duration(milliseconds: 20),
    Duration sendTimeout = const Duration(seconds: 5),
  }) => BattleStickersBloc(
    battleId: _battle,
    sendSticker: SendStickerUsecase(repository),
    watchStickers: WatchStickersUsecase(repository),
    watchConnection: WatchConnectionUsecase(connection),
    generateId: const GenerateIdUsecase(Uuid()),
    now: () => now,
    ownBubbleDuration: ownBubble,
    opponentBubbleDuration: opponentBubble,
    notSentDuration: notSent,
    retryDelay: retryDelay,
    sendTimeout: sendTimeout,
  );

  void update({
    BattlePhase phase = BattlePhase.question,
    Duration clockOffset = Duration.zero,
  }) => bloc.add(
    BattleStickersBattleUpdated(
      phase: phase,
      myUserId: _me,
      opponentUserId: _opponent,
      clockOffset: clockOffset,
    ),
  );

  /// Started, connected, in a question, no clock offset.
  Future<void> ready({Duration clockOffset = Duration.zero}) async {
    bloc.add(const BattleStickersStarted());
    update(clockOffset: clockOffset);
    await _flush();
  }

  StickerReceiptEntity receipt(
    SendStickerParamsEntity params, {
    Duration cooldown = const Duration(seconds: 4),
    Duration clockOffset = Duration.zero,
  }) {
    final DateTime serverNow = now.add(clockOffset);
    return StickerReceiptEntity(
      battleId: params.battleId,
      submissionId: params.submissionId,
      senderUserId: _me,
      stickerId: params.stickerId,
      sentAt: serverNow,
      nextAllowedAt: serverNow.add(cooldown),
    );
  }

  IncomingStickerEntity incoming({
    String eventId = 'e1',
    int sequence = 1,
    String battleId = _battle,
    String? submissionId,
    String sender = _opponent,
    StickerId stickerId = StickerId.lol,
    DateTime? sentAt,
  }) => IncomingStickerEntity(
    eventId: eventId,
    sequence: sequence,
    battleId: battleId,
    submissionId: submissionId ?? 's-$eventId',
    senderUserId: sender,
    stickerId: stickerId,
    sentAt: sentAt ?? now,
  );

  Future<void> receive(IncomingStickerEntity sticker) async {
    repository.stickers.add(sticker);
    await _flush();
  }

  Future<void> send([StickerId id = StickerId.gg]) async {
    bloc.add(BattleStickerSendRequested(id));
    await _flush();
  }

  setUp(() {
    repository = _FakeBattleRepository();
    connection = _FakeConnection();
    now = DateTime.utc(2026, 11, 15, 3);
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await repository.stickers.close();
    await connection.changes.close();
  });

  group('sending', () {
    test('nothing is sent before the battle phase is known', () async {
      bloc.add(const BattleStickersStarted());
      await _flush();

      await send();

      expect(repository.sends, isEmpty);
      expect(bloc.stateValue.ownBubble, isNull);
    });

    test('nothing is sent while the connection is down', () async {
      connection.status = RealtimeStatus.disconnected;
      await ready();

      await send();

      expect(bloc.stateValue.canSend, isFalse);
      expect(repository.sends, isEmpty);
    });

    test('an unknown sticker is never sent', () async {
      await ready();

      await send(StickerId.unknown);

      expect(repository.sends, isEmpty);
    });

    test('nothing is sent in a finished or cancelled battle', () async {
      await ready();
      for (final BattlePhase phase in <BattlePhase>[
        BattlePhase.finished,
        BattlePhase.cancelled,
      ]) {
        update(phase: phase);
        await _flush();
        await send();
      }

      expect(repository.sends, isEmpty);
    });

    test('a tap plays the own bubble at once and blocks a second send while '
        'the request is in flight', () async {
      await ready();

      await send(StickerId.fire);
      await send(StickerId.gg);

      expect(repository.sends, hasLength(1));
      final SendStickerParamsEntity params = repository.sends.single;
      expect(params.battleId, _battle);
      expect(params.stickerId, StickerId.fire);
      expect(bloc.stateValue.sendingSubmissionId, params.submissionId);
      expect(
        bloc.stateValue.ownBubble,
        OwnStickerBubble(
          submissionId: params.submissionId,
          stickerId: StickerId.fire,
          status: OwnStickerStatus.sending,
        ),
      );
    });

    test('acceptance marks the same bubble sent (no replay) and starts the '
        'cooldown from nextAllowedAt on the local clock', () async {
      const Duration offset = Duration(seconds: 10);
      await ready(clockOffset: offset);
      await send();
      final SendStickerParamsEntity params = repository.sends.single;

      repository.answer(Right(receipt(params, clockOffset: offset)));
      await _flush();

      expect(bloc.stateValue.ownBubble?.submissionId, params.submissionId);
      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.sent);
      expect(bloc.stateValue.isSending, isFalse);
      expect(bloc.stateValue.cooldownUntil, now.add(const Duration(seconds: 4)));
      expect(bloc.stateValue.canSend, isFalse);
    });

    test(
      'the cooldown ends at its deadline and the next tap uses a new id',
      () async {
        await ready();
        await send();
        final SendStickerParamsEntity first = repository.sends.single;
        repository.answer(
          Right(receipt(first, cooldown: const Duration(milliseconds: 40))),
        );
        await _flush();
        expect(bloc.stateValue.isCoolingDown, isTrue);

        now = now.add(const Duration(milliseconds: 40));
        await _flush(60);

        expect(bloc.stateValue.cooldownUntil, isNull);
        expect(bloc.stateValue.canSend, isTrue);
        await send();
        expect(repository.sends, hasLength(2));
        expect(repository.sends.last.submissionId, isNot(first.submissionId));
      },
    );

    test(
      'a receipt whose deadline already passed leaves no cooldown',
      () async {
        await ready();
        await send();
        final SendStickerParamsEntity params = repository.sends.single;
        final StickerReceiptEntity late = receipt(params);
        now = now.add(const Duration(seconds: 5));

        repository.answer(Right(late));
        await _flush();

        expect(bloc.stateValue.cooldownUntil, isNull);
        expect(bloc.stateValue.canSend, isTrue);
      },
    );

    test('the own bubble disappears after its display window', () async {
      bloc = build(ownBubble: const Duration(milliseconds: 40));
      await ready();
      await send();
      repository.answer(Right(receipt(repository.sends.single)));
      await _flush();
      expect(bloc.stateValue.ownBubble, isNotNull);

      await _flush(60);

      expect(bloc.stateValue.ownBubble, isNull);
    });
  });

  group('send failures', () {
    test('STICKER_COOLDOWN quietly removes the bubble and syncs the cooldown '
        'from resetsAt (server clock)', () async {
      const Duration offset = Duration(seconds: -3);
      await ready(clockOffset: offset);
      await send();

      repository.answer(
        Left(
          _api(
            ApiErrorCodes.stickerCooldown,
            status: 429,
            resetsAt: now.add(offset).add(const Duration(milliseconds: 2750)),
            retryAfter: const Duration(seconds: 3),
          ),
        ),
      );
      await _flush();

      expect(bloc.stateValue.ownBubble, isNull);
      expect(bloc.stateValue.isSending, isFalse);
      expect(
        bloc.stateValue.cooldownUntil,
        now.add(const Duration(milliseconds: 2750)),
      );
    });

    test('STICKER_COOLDOWN without resetsAt waits Retry-After', () async {
      await ready();
      await send();

      repository.answer(
        Left(
          _api(
            ApiErrorCodes.stickerCooldown,
            status: 429,
            retryAfter: const Duration(seconds: 3),
          ),
        ),
      );
      await _flush();

      expect(bloc.stateValue.cooldownUntil, now.add(const Duration(seconds: 3)));
      expect(bloc.stateValue.ownBubble, isNull);
    });

    test('STICKER_COOLDOWN without any time waits a full cooldown', () async {
      await ready();
      await send();

      repository.answer(Left(_api(ApiErrorCodes.stickerCooldown, status: 429)));
      await _flush();

      expect(bloc.stateValue.cooldownUntil, now.add(BattleStickersBloc.cooldown));
    });

    test('STICKERS_NOT_ALLOWED marks the bubble Not sent, closes sends and '
        'asks for a battle refresh until the phase changes', () async {
      await ready();
      await send();

      repository.answer(Left(_api(ApiErrorCodes.stickersNotAllowed)));
      await _flush();

      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
      expect(bloc.stateValue.serverClosed, isTrue);
      expect(bloc.stateValue.battleRefreshTicket, 1);
      expect(bloc.stateValue.canSend, isFalse);
      expect(bloc.stateValue.cooldownUntil, isNull);

      update(phase: BattlePhase.reveal);
      await _flush();

      expect(bloc.stateValue.serverClosed, isFalse);
      expect(bloc.stateValue.canSend, isTrue);
    });

    test(
      'BATTLE_NOT_FOUND marks Not sent and asks for a battle refresh',
      () async {
        await ready();
        await send();

        repository.answer(
          Left(_api(ApiErrorCodes.battleNotFound, status: 404)),
        );
        await _flush();

        expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
        expect(bloc.stateValue.battleRefreshTicket, 1);
        expect(bloc.stateValue.serverClosed, isFalse);
      },
    );

    for (final ApiFailure failure in <ApiFailure>[
      _api(ApiErrorCodes.validationError, status: 400),
      _api(ApiErrorCodes.invalidStickerId, status: 400),
      _api(ApiErrorCodes.idempotencyConflict),
      _api(ApiErrorCodes.unauthorized, status: 401),
      _api(ApiErrorCodes.internalError, status: 500),
    ]) {
      test('${failure.code} is Not sent without any retry', () async {
        await ready();
        await send();

        repository.answer(Left(failure));
        await _flush(40);

        expect(repository.sends, hasLength(1));
        expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
        expect(bloc.stateValue.battleRefreshTicket, 0);
        expect(bloc.stateValue.canSend, isTrue);
      });
    }

    test('the Not sent bubble hides after its shorter window', () async {
      bloc = build(
        ownBubble: const Duration(seconds: 3),
        notSent: const Duration(milliseconds: 40),
      );
      await ready();
      await send();
      repository.answer(Left(_api(ApiErrorCodes.internalError, status: 500)));
      await _flush();
      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);

      await _flush(60);

      expect(bloc.stateValue.ownBubble, isNull);
    });
  });

  group('transport retry', () {
    test(
      'a connection failure is retried once with the same submissionId',
      () async {
        await ready();
        await send();
        repository.answer(const Left(ConnectionFailure()));
        await _flush(40);

        expect(repository.sends, hasLength(2));
        expect(
          repository.sends.last.submissionId,
          repository.sends.first.submissionId,
        );
        repository.answer(Right(receipt(repository.sends.last)));
        await _flush();

        expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.sent);
        expect(
          bloc.stateValue.ownBubble?.submissionId,
          repository.sends.first.submissionId,
        );
      },
    );

    test('a second transport failure ends as Not sent', () async {
      await ready();
      await send();
      repository.answer(const Left(TimeoutFailure()));
      await _flush(40);
      repository.answer(const Left(TimeoutFailure()));
      await _flush(40);

      expect(repository.sends, hasLength(2));
      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
      expect(bloc.stateValue.isSending, isFalse);
    });

    test('no retry after the connection flapped during the wait', () async {
      bloc = build(retryDelay: const Duration(milliseconds: 40));
      await ready();
      await send();
      repository.answer(const Left(ConnectionFailure()));
      await _flush();

      connection.set(RealtimeStatus.disconnected);
      await _flush();
      connection.set(RealtimeStatus.connected);
      await _flush(60);

      expect(repository.sends, hasLength(1));
      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
    });

    test('closing during the retry wait sends nothing more', () async {
      bloc = build(retryDelay: const Duration(milliseconds: 40));
      await ready();
      await send();
      repository.answer(const Left(ConnectionFailure()));
      await _flush();

      await bloc.close();
      await _flush(60);

      expect(repository.sends, hasLength(1));
    });
  });

  group('slow sends', () {
    test(
      'an attempt longer than sendTimeout is retried once with the same '
      'id, then shown as Not sent although the bubble already expired',
      () async {
        bloc = build(
          ownBubble: const Duration(milliseconds: 30),
          sendTimeout: const Duration(milliseconds: 40),
        );
        await ready();
        await send();

        await _flush(70);
        expect(repository.sends, hasLength(2), reason: 'one retry');
        expect(
          repository.sends.last.submissionId,
          repository.sends.first.submissionId,
        );
        expect(bloc.stateValue.ownBubble, isNull, reason: 'display window passed');
        expect(bloc.stateValue.isSending, isTrue);

        await _flush(60);
        expect(repository.sends, hasLength(2), reason: 'no unbounded retry');
        expect(bloc.stateValue.isSending, isFalse);
        expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
        expect(
          bloc.stateValue.ownBubble?.submissionId,
          repository.sends.first.submissionId,
        );
        expect(bloc.stateValue.ownBubble?.stickerId, StickerId.gg);
      },
    );

    test('a late answer to a timed-out attempt is ignored', () async {
      // First attempt times out at 60 ms, the retry starts at once and
      // has until 120 ms; both answers arrive at about 85 ms.
      bloc = build(
        sendTimeout: const Duration(milliseconds: 60),
        retryDelay: Duration.zero,
      );
      await ready();
      await send();
      await _flush(80);
      expect(repository.sends, hasLength(2));

      repository.answer(Right(receipt(repository.sends.first)));
      await _flush();
      expect(bloc.stateValue.isSending, isTrue, reason: 'still the retry');

      repository.answer(Right(receipt(repository.sends.last)));
      await _flush();
      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.sent);
    });

    test(
      'a transport failure after the bubble expired is still retried',
      () async {
        bloc = build(ownBubble: const Duration(milliseconds: 20));
        await ready();
        await send();
        await _flush(30);
        expect(bloc.stateValue.ownBubble, isNull);

        repository.answer(const Left(ConnectionFailure()));
        await _flush(40);

        expect(repository.sends, hasLength(2));
      },
    );

    test(
      'STICKERS_NOT_ALLOWED after the bubble expired shows nothing',
      () async {
        bloc = build(ownBubble: const Duration(milliseconds: 20));
        await ready();
        await send();
        await _flush(30);

        repository.answer(Left(_api(ApiErrorCodes.stickersNotAllowed)));
        await _flush();

        expect(bloc.stateValue.ownBubble, isNull);
        expect(bloc.stateValue.serverClosed, isTrue);
      },
    );

    test('a receipt of another submission is not a confirmation', () async {
      await ready();
      await send();
      final SendStickerParamsEntity params = repository.sends.single;

      repository.answer(
        Right(
          receipt(
            SendStickerParamsEntity(
              battleId: params.battleId,
              stickerId: params.stickerId,
              submissionId: 'someone-else',
            ),
          ),
        ),
      );
      await _flush();

      expect(bloc.stateValue.ownBubble?.status, OwnStickerStatus.notSent);
      expect(bloc.stateValue.cooldownUntil, isNull);
    });
  });

  group('late answers', () {
    test('the end of the battle clears the bubble; a late acceptance revives '
        'nothing', () async {
      await ready();
      await send();

      update(phase: BattlePhase.finished);
      await _flush();
      expect(bloc.stateValue.ownBubble, isNull);
      expect(bloc.stateValue.isSending, isFalse);

      repository.answer(Right(receipt(repository.sends.single)));
      await _flush();

      expect(bloc.stateValue.ownBubble, isNull);
      expect(bloc.stateValue.cooldownUntil, isNull);
    });

    test(
      'an acceptance after the bubble expired only settles the cooldown',
      () async {
        bloc = build(ownBubble: const Duration(milliseconds: 20));
        await ready();
        await send();
        await _flush(40);
        expect(bloc.stateValue.ownBubble, isNull);

        repository.answer(Right(receipt(repository.sends.single)));
        await _flush();

        expect(bloc.stateValue.ownBubble, isNull);
        expect(bloc.stateValue.isSending, isFalse);
        expect(bloc.stateValue.cooldownUntil, isNotNull);
      },
    );
  });

  group('incoming stickers', () {
    test('a sticker from the opponent plays in the opponent bubble and '
        'expires', () async {
      bloc = build(opponentBubble: const Duration(milliseconds: 40));
      await ready();

      await receive(incoming(eventId: 'e1'));

      expect(
        bloc.stateValue.opponentBubble,
        const OpponentStickerBubble(eventId: 'e1', stickerId: StickerId.lol),
      );
      await _flush(60);
      expect(bloc.stateValue.opponentBubble, isNull);
    });

    test('a newer sticker replaces the bubble with a new key', () async {
      await ready();
      await receive(incoming(eventId: 'e1'));

      await receive(
        incoming(eventId: 'e2', sequence: 2, stickerId: StickerId.lol),
      );

      expect(bloc.stateValue.opponentBubble?.eventId, 'e2');
    });

    test('an old expiry timer never clears a newer bubble', () async {
      bloc = build(opponentBubble: const Duration(milliseconds: 50));
      await ready();
      await receive(incoming(eventId: 'e1'));
      await _flush(30);

      await receive(incoming(eventId: 'e2', sequence: 2));
      await _flush(30);

      expect(bloc.stateValue.opponentBubble?.eventId, 'e2');
    });

    test('nothing is shown before the first battle snapshot', () async {
      bloc.add(const BattleStickersStarted());
      await _flush();

      await receive(incoming());

      expect(bloc.stateValue.opponentBubble, isNull);
    });

    final Map<String, IncomingStickerEntity Function(DateTime now)> dropped =
        <String, IncomingStickerEntity Function(DateTime now)>{
          'another battle': (DateTime now) => IncomingStickerEntity(
            eventId: 'e1',
            sequence: 1,
            battleId: 'other',
            submissionId: 's1',
            senderUserId: _opponent,
            stickerId: StickerId.lol,
            sentAt: now,
          ),
          'an own echo': (DateTime now) => IncomingStickerEntity(
            eventId: 'e1',
            sequence: 1,
            battleId: _battle,
            submissionId: 's1',
            senderUserId: _me,
            stickerId: StickerId.lol,
            sentAt: now,
          ),
          'an unknown sender': (DateTime now) => IncomingStickerEntity(
            eventId: 'e1',
            sequence: 1,
            battleId: _battle,
            submissionId: 's1',
            senderUserId: 'stranger',
            stickerId: StickerId.lol,
            sentAt: now,
          ),
          'an unknown sticker id': (DateTime now) => IncomingStickerEntity(
            eventId: 'e1',
            sequence: 1,
            battleId: _battle,
            submissionId: 's1',
            senderUserId: _opponent,
            stickerId: StickerId.unknown,
            sentAt: now,
          ),
          'a sticker older than 5 s by the server clock': (DateTime now) =>
              IncomingStickerEntity(
                eventId: 'e1',
                sequence: 1,
                battleId: _battle,
                submissionId: 's1',
                senderUserId: _opponent,
                stickerId: StickerId.lol,
                sentAt: now.subtract(const Duration(seconds: 6)),
              ),
        };
    dropped.forEach((
      String name,
      IncomingStickerEntity Function(DateTime now) make,
    ) {
      test('$name is dropped silently', () async {
        await ready();

        await receive(make(now));

        expect(bloc.stateValue.opponentBubble, isNull);
      });
    });

    test(
      'staleness uses the server clock offset, not the local clock',
      () async {
        const Duration offset = Duration(seconds: -10);
        await ready(clockOffset: offset);

        // Sent 1 s ago on the server clock, 11 s ago on the local one.
        await receive(
          incoming(
            sentAt: now.add(offset).subtract(const Duration(seconds: 1)),
          ),
        );

        expect(bloc.stateValue.opponentBubble?.eventId, 'e1');
      },
    );

    test(
      'nothing is shown in a finished battle; the end clears the bubble',
      () async {
        await ready();
        await receive(incoming(eventId: 'e1'));
        expect(bloc.stateValue.opponentBubble, isNotNull);

        update(phase: BattlePhase.finished);
        await _flush();
        expect(bloc.stateValue.opponentBubble, isNull);

        await receive(incoming(eventId: 'e2', sequence: 2));
        expect(bloc.stateValue.opponentBubble, isNull);
      },
    );

    test('duplicates by eventId or submissionId and older sequences are '
        'dropped', () async {
      bloc = build(opponentBubble: const Duration(milliseconds: 20));
      await ready();
      await receive(incoming(eventId: 'e1', sequence: 5, submissionId: 's1'));
      await _flush(40);
      expect(bloc.stateValue.opponentBubble, isNull);

      await receive(incoming(eventId: 'e1', sequence: 6, submissionId: 's9'));
      expect(bloc.stateValue.opponentBubble, isNull, reason: 'same eventId');

      await receive(incoming(eventId: 'e2', sequence: 7, submissionId: 's1'));
      expect(bloc.stateValue.opponentBubble, isNull, reason: 'same submissionId');

      await receive(incoming(eventId: 'e3', sequence: 5, submissionId: 's3'));
      expect(bloc.stateValue.opponentBubble, isNull, reason: 'sequence 5 <= 5');

      await receive(incoming(eventId: 'e4', sequence: 9, submissionId: 's4'));
      expect(bloc.stateValue.opponentBubble?.eventId, 'e4', reason: 'gaps are fine');
    });

    test('a sticker received while disconnected neither displays nor consumes '
        'its ids before the next connection', () async {
      await ready();
      connection.set(RealtimeStatus.disconnected);
      await _flush();

      await receive(incoming(eventId: 'during-disconnect', sequence: 40));
      expect(bloc.stateValue.opponentBubble, isNull);

      connection.set(RealtimeStatus.connected);
      await _flush();
      await receive(incoming(eventId: 'during-disconnect', sequence: 1));

      expect(bloc.stateValue.opponentBubble?.eventId, 'during-disconnect');
    });

    test(
      'a reconnect starts a new sequence baseline (backend restart)',
      () async {
        await ready();
        await receive(incoming(eventId: 'e1', sequence: 40));

        connection.set(RealtimeStatus.disconnected);
        await _flush();
        connection.set(RealtimeStatus.connected);
        await _flush();
        await receive(incoming(eventId: 'e2', sequence: 1));

        expect(bloc.stateValue.opponentBubble?.eventId, 'e2');
      },
    );

    test('hiding the opponent clears the bubble and drops new stickers; '
        'showing again replays nothing', () async {
      await ready();
      await receive(incoming(eventId: 'e1'));

      bloc.add(const BattleStickersOpponentHiddenToggled());
      await _flush();
      expect(bloc.stateValue.opponentHidden, isTrue);
      expect(bloc.stateValue.opponentBubble, isNull);

      await receive(incoming(eventId: 'e2', sequence: 2));
      expect(bloc.stateValue.opponentBubble, isNull);

      bloc.add(const BattleStickersOpponentHiddenToggled());
      await _flush();
      expect(bloc.stateValue.opponentHidden, isFalse);
      expect(bloc.stateValue.opponentBubble, isNull);
    });

    test('hiding the opponent keeps the own bubble and the cooldown', () async {
      await ready();
      await send();
      repository.answer(Right(receipt(repository.sends.single)));
      await _flush();

      bloc.add(const BattleStickersOpponentHiddenToggled());
      await _flush();

      expect(bloc.stateValue.ownBubble, isNotNull);
      expect(bloc.stateValue.cooldownUntil, isNotNull);
    });
  });
}
