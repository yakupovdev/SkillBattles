import 'dart:async';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';

EntitlementsEntity _rights({int version = 1, bool pro = false}) =>
    EntitlementsEntity(
      isPro: pro,
      version: version,
      unlimitedRanked: pro,
      historyMatchLimit: pro ? null : 10,
      canViewCorrectAnswers: pro,
      canViewExplanations: pro,
      canViewAdvancedAnalytics: pro,
      canFilterMistakes: pro,
    );

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

BattleSnapshotEntity _snapshot({
  required int version,
  BattlePhase phase = BattlePhase.question,
  String roundId = 'r1',
  String? mySelection,
  EntitlementsEntity? rights,
}) {
  final DateTime now = DateTime.now().toUtc();
  return BattleSnapshotEntity(
    id: 'b1',
    disciplineCode: 'SAT_MATH',
    mode: BattleMode.ranked,
    seasonId: 'FALL_2026',
    phase: phase,
    version: version,
    serverTime: now,
    receivedAt: now,
    questionCount: 5,
    overtimePlayed: false,
    readyDeadline: null,
    countdownEndsAt: null,
    nextRoundStartsAt: null,
    players: <BattlePlayerEntity>[_player('me'), _player('them')],
    round: BattleRoundEntity(
      id: roundId,
      number: 1,
      isOvertime: false,
      startedAt: now,
      // Far away: no fallback re-read inside the test.
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
      mySelectedOptionId: mySelection,
      reveal: null,
    ),
    result: null,
    entitlements: rights ?? _rights(),
    myUserId: 'me',
  );
}

final class _FakeBattleRepository implements BattleRepository {
  final StreamController<BattleSnapshotEntity> events =
      StreamController<BattleSnapshotEntity>.broadcast();
  BattleSnapshotEntity snapshot = _snapshot(version: 2);
  final List<SubmitAnswerParamsEntity> submissions =
      <SubmitAnswerParamsEntity>[];
  final List<Either<Failure, AnswerReceiptEntity>> answerResults =
      <Either<Failure, AnswerReceiptEntity>>[];

  @override
  Future<Either<Failure, BattleSnapshotEntity>> getBattle(
    String battleId,
  ) async => Right(snapshot);

  @override
  Future<Either<Failure, BattleSnapshotEntity>> setReady(
    String battleId,
  ) async => Right(snapshot);

  @override
  Future<Either<Failure, AnswerReceiptEntity>> submitAnswer(
    SubmitAnswerParamsEntity params,
  ) async {
    submissions.add(params);
    return answerResults.removeAt(0);
  }

  @override
  Future<Either<Failure, BattleSnapshotEntity>> surrender(
    String battleId,
  ) async => Right(snapshot);

  @override
  Stream<BattleSnapshotEntity> watchBattle(String battleId) => events.stream;

  @override
  Future<Either<Failure, StickerReceiptEntity>> sendSticker(
    SendStickerParamsEntity params,
  ) async => const Left(ConnectionFailure());

  @override
  Stream<IncomingStickerEntity> watchStickers(String battleId) =>
      const Stream<IncomingStickerEntity>.empty();
}

final class _FakeConnection implements ConnectionRepository {
  @override
  RealtimeStatus get status => RealtimeStatus.connected;

  @override
  Stream<RealtimeStatus> watchStatus() => const Stream<RealtimeStatus>.empty();
}

void main() {
  late _FakeBattleRepository repository;
  late BattleBloc bloc;

  setUp(() {
    repository = _FakeBattleRepository();
    bloc = BattleBloc(
      battleId: 'b1',
      getBattle: GetBattleUsecase(repository),
      setReady: SetReadyUsecase(repository),
      submitAnswer: SubmitAnswerUsecase(repository),
      surrender: SurrenderUsecase(repository),
      watchBattle: WatchBattleUsecase(repository),
      watchConnection: WatchConnectionUsecase(_FakeConnection()),
      generateId: const GenerateIdUsecase(Uuid()),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repository.events.close();
  });

  Future<void> started() async {
    bloc.add(const BattleStarted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  test(
    'an older version from an event never replaces a newer snapshot',
    () async {
      await started();
      expect(bloc.stateValue.snapshot?.version, 2);

      repository.events.add(_snapshot(version: 1));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.stateValue.snapshot?.version, 2);

      repository.events.add(_snapshot(version: 3));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.stateValue.snapshot?.version, 3);
    },
  );

  test('the same battle version with new entitlements is applied', () async {
    await started();

    repository.events.add(
      _snapshot(version: 2, rights: _rights(version: 2, pro: true)),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.stateValue.snapshot?.entitlements.isPro, isTrue);
  });

  test(
    'a retry after a failed submit reuses the submissionId and option',
    () async {
      repository.answerResults
        ..add(const Left(ConnectionFailure()))
        ..add(
          Right(
            AnswerReceiptEntity(
              roundId: 'r1',
              submissionId: 'x',
              acceptedAt: DateTime.utc(2026),
            ),
          ),
        );
      await started();

      bloc.add(const BattleOptionSelected('o2'));
      bloc.add(const BattleAnswerSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(bloc.stateValue.submission?.status, SubmissionStatus.failed);
      // The choice is locked to what was sent.
      expect(bloc.stateValue.canChangeSelection, isFalse);

      bloc.add(const BattleAnswerSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.submissions, hasLength(2));
      expect(
        repository.submissions[0].submissionId,
        repository.submissions[1].submissionId,
      );
      expect(repository.submissions[1].optionId, 'o2');
      expect(bloc.stateValue.submission?.status, SubmissionStatus.accepted);
    },
  );

  test(
    "the server's accepted answer is final and resets on a new round",
    () async {
      repository.snapshot = _snapshot(version: 2, mySelection: 'o3');
      await started();

      expect(bloc.stateValue.submission?.status, SubmissionStatus.accepted);
      expect(bloc.stateValue.selectedOptionId, 'o3');
      expect(bloc.stateValue.canSubmit, isFalse);

      repository.events.add(_snapshot(version: 3, roundId: 'r2'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.stateValue.submission, isNull);
      expect(bloc.stateValue.selectedOptionId, isNull);
    },
  );

  test('selection is ignored outside the question phase', () async {
    repository.snapshot = _snapshot(version: 2, phase: BattlePhase.reveal);
    await started();

    bloc.add(const BattleOptionSelected('o1'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.stateValue.selectedOptionId, isNull);
  });
}
