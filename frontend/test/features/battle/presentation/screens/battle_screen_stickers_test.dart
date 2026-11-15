import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_stickers_usecase.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';
import 'package:skill_battles/features/battle/presentation/controllers/sticker_compositions.dart';
import 'package:skill_battles/features/battle/presentation/screens/battle_screen.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_bubble.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_trigger_button.dart';

const double _columnWidth = 880;

final Map<String, LottieComposition> _parsed = <String, LottieComposition>{};

BattlePlayerEntity _player(String id) => BattlePlayerEntity(
  id: id,
  nickname: id,
  isPro: false,
  rating: 1000,
  rankCode: 'SILVER_I',
  ready: true,
  connected: true,
  reconnectDeadline: null,
  score: 0,
  correctCount: 0,
  streak: 0,
  answeredCurrentRound: false,
);

BattleSnapshotEntity _snapshot() {
  final DateTime now = DateTime.now().toUtc();
  return BattleSnapshotEntity(
    id: 'b1',
    disciplineCode: 'SAT_MATH',
    mode: BattleMode.ranked,
    seasonId: 'FALL_2026',
    phase: BattlePhase.question,
    version: 2,
    serverTime: now,
    receivedAt: now,
    questionCount: 5,
    overtimePlayed: false,
    readyDeadline: null,
    countdownEndsAt: null,
    nextRoundStartsAt: null,
    players: <BattlePlayerEntity>[_player('me'), _player('timur.b')],
    round: BattleRoundEntity(
      id: 'r1',
      number: 1,
      isOvertime: false,
      startedAt: now,
      deadline: now.add(const Duration(hours: 1)),
      limitSeconds: 45,
      question: const QuestionEntity(
        id: 'q1',
        topicCode: 'T',
        topicName: 'Topic',
        difficulty: Difficulty.easy,
        prompt: 'What is 2 + 2?',
        options: <QuestionOptionEntity>[
          QuestionOptionEntity(id: 'o1', text: '3'),
          QuestionOptionEntity(id: 'o2', text: '4'),
          QuestionOptionEntity(id: 'o3', text: '5'),
          QuestionOptionEntity(id: 'o4', text: '6'),
        ],
      ),
      mySelectedOptionId: null,
      reveal: null,
    ),
    result: null,
    entitlements: const EntitlementsEntity(
      isPro: false,
      version: 1,
      unlimitedRanked: false,
      historyMatchLimit: 10,
      canViewCorrectAnswers: false,
      canViewExplanations: false,
      canViewAdvancedAnalytics: false,
      canFilterMistakes: false,
    ),
    myUserId: 'me',
  );
}

final class _Battles implements BattleRepository {
  final BattleSnapshotEntity snapshot = _snapshot();
  final StreamController<BattleSnapshotEntity> events =
      StreamController<BattleSnapshotEntity>.broadcast();
  final StreamController<IncomingStickerEntity> stickers =
      StreamController<IncomingStickerEntity>.broadcast();
  final List<SendStickerParamsEntity> sends = <SendStickerParamsEntity>[];
  final List<Completer<Either<Failure, StickerReceiptEntity>>> pending =
      <Completer<Either<Failure, StickerReceiptEntity>>>[];
  int reads = 0;

  @override
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(
    String battleId,
  ) async {
    reads++;
    return Right(snapshot);
  }

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
  Stream<BattleSnapshotEntity> watchBattle(String battleId) => events.stream;

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
}

final class _Connected implements ConnectionRepository {
  @override
  RealtimeStatus get status => RealtimeStatus.connected;

  @override
  Stream<RealtimeStatus> watchStatus() => const Stream<RealtimeStatus>.empty();
}

/// The account bloc is only listened to by the screen; nothing calls it.
final class _UnusedAccount implements AccountRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _UnusedAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _Harness {
  _Harness() : battles = _Battles() {
    final WatchConnectionUsecase connection = WatchConnectionUsecase(
      _Connected(),
    );
    battle = BattleBloc(
      battleId: 'b1',
      getBattle: GetBattleUsecase(battles),
      setReady: SetReadyUsecase(battles),
      submitAnswer: SubmitAnswerUsecase(battles),
      surrender: SurrenderUsecase(battles),
      watchBattle: WatchBattleUsecase(battles),
      watchConnection: connection,
      generateId: const GenerateIdUsecase(Uuid()),
    )..add(const BattleStarted());
    stickers = BattleStickersBloc(
      battleId: 'b1',
      sendSticker: SendStickerUsecase(battles),
      watchStickers: WatchStickersUsecase(battles),
      watchConnection: connection,
      generateId: const GenerateIdUsecase(Uuid()),
    )..add(const BattleStickersStarted());
    account = AccountBloc(
      getAccountState: GetAccountStateUsecase(_UnusedAccount()),
      watchAccountChanges: WatchAccountChangesUsecase(_UnusedAccount()),
      watchSignedIn: WatchSignedInUsecase(_UnusedAuth()),
      logout: LogoutUsecase(_UnusedAuth()),
      isSignedIn: true,
    );
  }

  final _Battles battles;
  late final BattleBloc battle;
  late final BattleStickersBloc stickers;
  late final AccountBloc account;

  Future<void> close() async {
    await stickers.close();
    await battle.close();
    await account.close();
    await battles.events.close();
    await battles.stickers.close();
  }
}

final class _ScreenTestApp extends StatelessWidget {
  const _ScreenTestApp({required this.harness});

  final _Harness harness;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    home: StickerCompositionsScope(
      loader: (String path) async => _parsed[path]!,
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AccountBloc>.value(value: harness.account),
          BlocProvider<BattleBloc>.value(value: harness.battle),
          BlocProvider<BattleStickersBloc>.value(value: harness.stickers),
        ],
        child: const BattleScreen(battleId: 'b1'),
      ),
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _Harness harness,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_ScreenTestApp(harness: harness));
  for (int i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Unmounts the screen (stopping the time bar) and closes the blocs.
Future<void> _finish(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  bool isClosed = false;
  final Future<void> closing = harness.close().whenComplete(() {
    isClosed = true;
  });
  // Dart 3.14 async* cancellation can await a shared root-zone Future while
  // its continuation belongs to fake async. Drain both queues before awaiting.
  for (int i = 0; !isClosed && i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  expect(isClosed, isTrue, reason: 'all test-owned resources close');
  await closing;
}

Rect _column(double width) =>
    Rect.fromLTWH((width - _columnWidth) / 2, 0, _columnWidth, 10000);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final StickerId id in StickerId.supported) {
      final String path = StickerCompositions.assetOf(id);
      _parsed[path] = await LottieComposition.fromByteData(
        await rootBundle.load(path),
      );
    }
  });

  testWidgets('at 1440 px: the trigger opens the picker, a send plays the '
      'own bubble in the left gutter, and nothing touches the column or '
      'rebuilds the question', (WidgetTester tester) async {
    final _Harness harness = _Harness();
    try {
      await _pumpScreen(tester, harness, const Size(1440, 900));
      final Rect column = _column(1440);

      final Finder trigger = find.byType(StickerTriggerButton);
      expect(trigger, findsOneWidget);
      final Rect triggerRect = tester.getRect(trigger);
      expect(
        triggerRect.bottom,
        lessThanOrEqualTo(104),
        reason: 'in the header',
      );
      expect(triggerRect.right, lessThan(1440 / 2), reason: 'in your block');
      expect(
        tester.widget<StickerTriggerButton>(trigger).disabledMessage,
        isNull,
      );

      final BattleRoundView roundBefore = tester.widget<BattleRoundView>(
        find.byType(BattleRoundView),
      );

      await tester.tap(trigger);
      await tester.pump();
      final Finder picker = find.byType(StickerPicker);
      expect(picker, findsOneWidget);
      expect(tester.getRect(picker).overlaps(column), isFalse);
      expect(tester.getRect(picker).top, greaterThanOrEqualTo(122));

      await tester.tap(find.byKey(const ValueKey<StickerId>(StickerId.fire)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(harness.battles.sends.single.stickerId, StickerId.fire);
      expect(
        find.byType(StickerPicker),
        findsNothing,
        reason: 'closed on send',
      );
      final Finder bubble = find.byType(StickerBubble);
      expect(bubble, findsOneWidget);
      final Rect bubbleRect = tester.getRect(bubble);
      expect(bubbleRect.overlaps(column), isFalse);
      expect(bubbleRect.left, 64, reason: 'aligned with your avatar block');
      expect(
        tester.widget<StickerBubble>(bubble).variant,
        StickerBubbleVariant.outgoing,
      );
      expect(
        identical(
          roundBefore,
          tester.widget<BattleRoundView>(find.byType(BattleRoundView)),
        ),
        isTrue,
        reason: 'a sticker never rebuilds the question and the options',
      );

      // In flight: focus stays on the trigger after the picker closed, and
      // a tap opens nothing (a second send would be refused).
      expect(
        tester.widget<StickerTriggerButton>(trigger).disabledMessage,
        isNull,
      );
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'StickerTrigger');
      await tester.tap(trigger);
      await tester.pump();
      expect(find.byType(StickerPicker), findsNothing);

      final SendStickerParamsEntity params = harness.battles.sends.single;
      final DateTime now = DateTime.now().toUtc();
      harness.battles.pending
          .removeAt(0)
          .complete(
            Right(
              StickerReceiptEntity(
                battleId: params.battleId,
                submissionId: params.submissionId,
                senderUserId: 'me',
                stickerId: params.stickerId,
                sentAt: now,
                nextAllowedAt: now.add(const Duration(seconds: 4)),
              ),
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final StickerTriggerButton cooling = tester.widget<StickerTriggerButton>(
        trigger,
      );
      expect(cooling.cooldownUntil, isNotNull);
      expect(cooling.disabledMessage, isNull, reason: 'the ring, not Disabled');
      expect(
        find.descendant(of: trigger, matching: find.text('4')),
        findsOneWidget,
      );
    } finally {
      await _finish(tester, harness);
    }
  });

  testWidgets('an incoming sticker plays in the right gutter with the '
      "opponent's name", (WidgetTester tester) async {
    final _Harness harness = _Harness();
    try {
      await _pumpScreen(tester, harness, const Size(1440, 900));

      harness.battles.stickers.add(
        IncomingStickerEntity(
          eventId: 'e1',
          sequence: 1,
          battleId: 'b1',
          submissionId: 's1',
          senderUserId: 'timur.b',
          stickerId: StickerId.lol,
          sentAt: DateTime.now().toUtc(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final Finder bubble = find.byType(StickerBubble);
      expect(bubble, findsOneWidget);
      final Rect rect = tester.getRect(bubble);
      expect(rect.overlaps(_column(1440)), isFalse);
      expect(rect.right, 1440 - 64);
      expect(tester.widget<StickerBubble>(bubble).caption, 'timur.b');
      expect(find.bySemanticsLabel('timur.b sent LOL'), findsOneWidget);
    } finally {
      await _finish(tester, harness);
    }
  });

  testWidgets('below the 1280 px canvas no bubble shows and the trigger is '
      'off, so nothing can cover the column', (WidgetTester tester) async {
    final _Harness harness = _Harness();
    try {
      await _pumpScreen(tester, harness, const Size(1100, 900));

      expect(
        tester
            .widget<StickerTriggerButton>(find.byType(StickerTriggerButton))
            .disabledMessage,
        'Window too narrow for stickers',
      );
      harness.battles.stickers.add(
        IncomingStickerEntity(
          eventId: 'e1',
          sequence: 1,
          battleId: 'b1',
          submissionId: 's1',
          senderUserId: 'timur.b',
          stickerId: StickerId.lol,
          sentAt: DateTime.now().toUtc(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StickerBubble), findsNothing);
    } finally {
      await _finish(tester, harness);
    }
  });

  testWidgets('STICKERS_NOT_ALLOWED makes the battle screen read the battle '
      'again', (WidgetTester tester) async {
    final _Harness harness = _Harness();
    try {
      await _pumpScreen(tester, harness, const Size(1440, 900));
      final int readsBefore = harness.battles.reads;

      await tester.tap(find.byType(StickerTriggerButton));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<StickerId>(StickerId.gg)));
      await tester.pump();
      harness.battles.pending
          .removeAt(0)
          .complete(
            const Left(
              ApiFailure(
                statusCode: 409,
                errorCode: ApiErrorCodes.stickersNotAllowed,
                message: 'Stickers are not allowed after the battle ends.',
              ),
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.battles.reads, readsBefore + 1);
      expect(
        tester.widget<StickerBubble>(find.byType(StickerBubble)).variant,
        StickerBubbleVariant.notSent,
      );
    } finally {
      await _finish(tester, harness);
    }
  });
}
