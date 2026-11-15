import 'dart:async';
import 'dart:collection';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_stickers_usecase.dart';

part 'battle_stickers_event.dart';
part 'battle_stickers_state.dart';

/// Ephemeral battle stickers: the own and the opponent's bubble, the send
/// in flight, the server cooldown and the local "hide opponent" flag.
///
/// Kept apart from `BattleBloc`, so a sticker never rebuilds the question.
///
/// - Sending: allowed only when [BattleStickersState.canSend] (phase
///   WAITING_READY to REVEAL, connected, nothing in flight, no cooldown).
///   One `submissionId` per tap; the own bubble plays at once and a success
///   only marks it sent (no replay). A result is applied only while its
///   intent is still the one in flight, and touches the own bubble only
///   while that bubble is still the intent's, so a late answer never
///   replaces a newer bubble or revives a cleared one.
/// - Failures: STICKER_COOLDOWN quietly removes the bubble and syncs the
///   cooldown; STICKERS_NOT_ALLOWED and BATTLE_NOT_FOUND mark it Not sent and
///   ask for a battle refresh (the first one also closes sends until the
///   phase changes); a connection failure or timeout (an attempt longer than
///   [sendTimeout]) is retried exactly once with the same id, after
///   [retryDelay], while the intent, the phase and the connection are
///   unchanged; everything else is Not sent, shown even after the bubble's
///   display window (except STICKERS_NOT_ALLOWED, only while visible).
///   Nothing is ever resent on reconnect.
/// - Cooldown: a local deadline from the server's `nextAllowedAt` /
///   `resetsAt` minus the battle clock offset (or `Retry-After`), merged with
///   max, so an older receipt never shortens a later deadline.
/// - Incoming: shown only from the known opponent, in this battle, in an
///   allowed phase, for a known sticker, while not hidden, not seen before
///   (event and submission id), with a sequence above the baseline of the
///   current connection generation, and not older than [staleAfter] by the
///   server clock. Every transition into connected starts a new generation;
///   sticker gaps never trigger a battle recovery.
/// - A terminal phase clears both bubbles and the send in flight.
///
/// Transformers: sends are `droppable()` so two never overlap (the handler
/// also covers the single retry); every other handler is synchronous, so
/// the default transformer keeps arrival order.
final class BattleStickersBloc
    extends Bloc<BattleStickersEvent, BattleStickersState> {
  BattleStickersBloc({
    required this.battleId,
    required this._sendSticker,
    required this._watchStickers,
    required this._watchConnection,
    required this._generateId,
    DateTime Function()? now,
    this.ownBubbleDuration = const Duration(seconds: 3),
    this.opponentBubbleDuration = const Duration(seconds: 3),
    this.notSentDuration = const Duration(seconds: 2),
    this.retryDelay = const Duration(milliseconds: 500),
    this.sendTimeout = const Duration(seconds: 5),
    this.staleAfter = const Duration(seconds: 5),
  }) : _now = now ?? DateTime.now,
       super(const BattleStickersState()) {
    on<BattleStickersStarted>(_onStarted);
    on<BattleStickersBattleUpdated>(_onBattleUpdated);
    on<BattleStickerSendRequested>(_onSendRequested, transformer: droppable());
    on<BattleStickersOpponentHiddenToggled>(_onOpponentHiddenToggled);
    on<_IncomingStickerReceived>(_onIncomingSticker);
    on<_StickersConnectionChanged>(_onConnectionChanged);
    on<_StickerBubbleExpired>(_onBubbleExpired);
    on<_StickerCooldownEnded>(_onCooldownEnded);
  }

  /// Full length of a server cooldown, for the trigger ring.
  static const Duration cooldown = Duration(seconds: 4);

  final String battleId;
  final SendStickerUsecase _sendSticker;
  final WatchStickersUsecase _watchStickers;
  final WatchConnectionUsecase _watchConnection;
  final GenerateIdUsecase _generateId;
  final DateTime Function() _now;
  final Duration ownBubbleDuration;
  final Duration opponentBubbleDuration;
  final Duration notSentDuration;
  final Duration retryDelay;

  /// How long one attempt may take before it counts as a timeout. Far below
  /// the app-wide HTTP timeouts, so the final answer (or Not sent) arrives
  /// while the sticker still matters. A late server answer is ignored; a
  /// retry with the same id gets the original receipt.
  final Duration sendTimeout;

  /// Incoming events older than this (by the server clock) are dropped.
  final Duration staleAfter;

  /// How many incoming event / submission ids are remembered for dedupe.
  static const int _recentIdsLimit = 64;

  /// `Retry-After` is at least one second by contract.
  static const Duration _minRetryAfter = Duration(seconds: 1);

  StreamSubscription<IncomingStickerEntity>? _stickerSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  Timer? _ownBubbleTimer;
  Timer? _opponentBubbleTimer;
  Timer? _cooldownTimer;
  Timer? _retryTimer;
  Completer<void>? _retryWait;

  String? _myUserId;
  String? _opponentUserId;

  /// Server time minus local time, from the latest battle snapshot.
  Duration _clockOffset = Duration.zero;

  /// Bumped on every connection status change; a retry needs it unchanged.
  int _connectionEpoch = 0;

  /// Highest accepted sticker sequence of the current connection
  /// generation; `null` right after (re)connecting.
  int? _lastSequence;
  final _RecentIds _seenEventIds = _RecentIds(_recentIdsLimit);
  final _RecentIds _seenSubmissionIds = _RecentIds(_recentIdsLimit);

  void _onStarted(
    BattleStickersStarted event,
    Emitter<BattleStickersState> emit,
  ) {
    _stickerSubscription ??=
        _watchStickers(BattleParamsEntity(battleId: battleId))
            .listen((IncomingStickerEntity sticker) {
              if (!isClosed) add(_IncomingStickerReceived(sticker));
            });
    // Emits the current status first, then every change.
    _connectionSubscription ??= _watchConnection(const NoParams())
        .listen((RealtimeStatus status) {
          if (!isClosed) add(_StickersConnectionChanged(status));
        });
  }

  void _onBattleUpdated(
    BattleStickersBattleUpdated event,
    Emitter<BattleStickersState> emit,
  ) {
    _myUserId = event.myUserId;
    _opponentUserId = event.opponentUserId;
    _clockOffset = event.clockOffset;
    final bool phaseChanged = event.phase != state.phase;
    final bool terminal = event.phase.isTerminal;
    if (terminal) {
      // A late answer may still settle the request, but it finds no intent
      // and no bubble, so nothing reappears on the result.
      _ownBubbleTimer?.cancel();
      _opponentBubbleTimer?.cancel();
    }
    emit(
      state.copyWith(
        phase: event.phase,
        serverClosed: phaseChanged ? false : null,
        resetOwnBubble: terminal,
        resetOpponentBubble: terminal,
        resetSendingSubmissionId: terminal,
      ),
    );
  }

  Future<void> _onSendRequested(
    BattleStickerSendRequested event,
    Emitter<BattleStickersState> emit,
  ) async {
    final StickerId stickerId = event.stickerId;
    if (!stickerId.isKnown || !state.canSend) return;
    final String submissionId = _generateId(const NoParams());
    emit(
      state.copyWith(
        sendingSubmissionId: submissionId,
        ownBubble: OwnStickerBubble(
          submissionId: submissionId,
          stickerId: stickerId,
          status: OwnStickerStatus.sending,
        ),
      ),
    );
    _startBubbleTimer(StickerSide.own, submissionId, ownBubbleDuration);
    final SendStickerParamsEntity params = SendStickerParamsEntity(
      battleId: battleId,
      stickerId: stickerId,
      submissionId: submissionId,
    );
    final int epoch = _connectionEpoch;
    Either<Failure, StickerReceiptEntity> result = await _attempt(params);
    if (emit.isDone) return;
    if (_isTransportFailure(result.getLeft()) &&
        _canRetry(submissionId, epoch)) {
      await _waitBeforeRetry();
      if (emit.isDone) return;
      if (_canRetry(submissionId, epoch)) {
        // Same id: the server returns the original receipt if the first
        // attempt was accepted after all.
        result = await _attempt(params);
        if (emit.isDone) return;
      }
    }
    // A terminal phase settled this intent meanwhile.
    if (state.sendingSubmissionId != submissionId) return;
    result.match(
      (Failure failure) => _onSendFailed(failure, params, emit),
      (StickerReceiptEntity receipt) => _onSendAccepted(receipt, params, emit),
    );
  }

  /// One request, bounded by [sendTimeout].
  Future<Either<Failure, StickerReceiptEntity>> _attempt(
    SendStickerParamsEntity params,
  ) => _sendSticker(params).timeout(
    sendTimeout,
    onTimeout: () =>
        const Left<Failure, StickerReceiptEntity>(TimeoutFailure()),
  );

  bool _isTransportFailure(Failure? failure) =>
      failure is ConnectionFailure || failure is TimeoutFailure;

  /// The intent is still the current one (a terminal phase ends it), even
  /// if its bubble's display window has passed.
  bool _canRetry(String submissionId, int epoch) =>
      !isClosed &&
      state.sendingSubmissionId == submissionId &&
      state.isPhaseAllowed &&
      !state.serverClosed &&
      state.connection == RealtimeStatus.connected &&
      _connectionEpoch == epoch;

  /// A cancellable [retryDelay]; `close()` cancels the timer.
  Future<void> _waitBeforeRetry() {
    final Completer<void> completer = Completer<void>();
    _retryWait = completer;
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, completer.complete);
    return completer.future;
  }

  void _onSendAccepted(
    StickerReceiptEntity receipt,
    SendStickerParamsEntity params,
    Emitter<BattleStickersState> emit,
  ) {
    final String submissionId = params.submissionId;
    if (receipt.submissionId != submissionId ||
        receipt.battleId != params.battleId) {
      // Not a receipt of this intent: it was not confirmed.
      _markNotSent(params, emit);
      return;
    }
    final OwnStickerBubble? bubble = state.ownBubble;
    final DateTime? cooldownUntil = _mergeCooldown(
      _toLocal(receipt.nextAllowedAt),
    );
    emit(
      state.copyWith(
        resetSendingSubmissionId: true,
        // Already playing: only the status changes, the key stays.
        ownBubble: bubble != null && bubble.submissionId == submissionId
            ? bubble.copyWith(status: OwnStickerStatus.sent)
            : null,
        cooldownUntil: cooldownUntil,
        resetCooldownUntil: cooldownUntil == null,
      ),
    );
    _scheduleCooldownEnd(cooldownUntil);
  }

  void _onSendFailed(
    Failure failure,
    SendStickerParamsEntity params,
    Emitter<BattleStickersState> emit,
  ) {
    final String submissionId = params.submissionId;
    if (failure.hasCode(ApiErrorCodes.stickerCooldown)) {
      final bool ownsBubble = state.ownBubble?.submissionId == submissionId;
      if (ownsBubble) _ownBubbleTimer?.cancel();
      final DateTime? cooldownUntil = _mergeCooldown(
        _cooldownAfterRejection(failure),
      );
      emit(
        state.copyWith(
          resetSendingSubmissionId: true,
          resetOwnBubble: ownsBubble,
          cooldownUntil: cooldownUntil,
          resetCooldownUntil: cooldownUntil == null,
        ),
      );
      _scheduleCooldownEnd(cooldownUntil);
      return;
    }
    final bool notAllowed = failure.hasCode(ApiErrorCodes.stickersNotAllowed);
    final bool refreshBattle =
        notAllowed || failure.hasCode(ApiErrorCodes.battleNotFound);
    _markNotSent(
      params,
      emit,
      // The contract shows Not sent here only while the bubble is visible.
      onlyIfVisible: notAllowed,
      serverClosed: notAllowed ? true : null,
      battleRefreshTicket: refreshBattle ? state.battleRefreshTicket + 1 : null,
    );
  }

  /// Ends the intent and shows it as Not sent for [notSentDuration], also
  /// when its display window already passed (the user must learn it did
  /// not go through), unless [onlyIfVisible]. The cooldown is unchanged.
  void _markNotSent(
    SendStickerParamsEntity params,
    Emitter<BattleStickersState> emit, {
    bool onlyIfVisible = false,
    bool? serverClosed,
    int? battleRefreshTicket,
  }) {
    final String submissionId = params.submissionId;
    final OwnStickerBubble? bubble = state.ownBubble;
    final bool isVisible = bubble?.submissionId == submissionId;
    final OwnStickerBubble? notSent = isVisible || !onlyIfVisible
        ? OwnStickerBubble(
            submissionId: submissionId,
            stickerId: params.stickerId,
            status: OwnStickerStatus.notSent,
          )
        : null;
    emit(
      state.copyWith(
        resetSendingSubmissionId: true,
        ownBubble: notSent,
        serverClosed: serverClosed,
        battleRefreshTicket: battleRefreshTicket,
      ),
    );
    if (notSent != null) {
      _startBubbleTimer(StickerSide.own, submissionId, notSentDuration);
    }
  }

  /// The local deadline of a 429: `resetsAt` by the server clock, else
  /// `Retry-After` from now, else a full [cooldown].
  DateTime _cooldownAfterRejection(Failure failure) {
    if (failure is ApiFailure) {
      final DateTime? resetsAt = failure.resetsAt;
      if (resetsAt != null) return _toLocal(resetsAt);
      final Duration? retryAfter = failure.retryAfter;
      if (retryAfter != null) {
        return _now().add(
          retryAfter < _minRetryAfter ? _minRetryAfter : retryAfter,
        );
      }
    }
    return _now().add(cooldown);
  }

  /// A server instant on the local clock, in the zone of [_now].
  DateTime _toLocal(DateTime serverInstant) {
    final DateTime local = serverInstant.subtract(_clockOffset);
    return _now().isUtc ? local.toUtc() : local.toLocal();
  }

  /// The later of the current deadline and [candidate]; `null` when that
  /// has already passed.
  DateTime? _mergeCooldown(DateTime candidate) {
    final DateTime? current = state.cooldownUntil;
    final DateTime merged = current != null && current.isAfter(candidate)
        ? current
        : candidate;
    return merged.isAfter(_now()) ? merged : null;
  }

  void _scheduleCooldownEnd(DateTime? deadline) {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    if (deadline == null) return;
    _cooldownTimer = Timer(deadline.difference(_now()), () {
      if (!isClosed) add(_StickerCooldownEnded(deadline));
    });
  }

  void _onCooldownEnded(
    _StickerCooldownEnded event,
    Emitter<BattleStickersState> emit,
  ) {
    if (state.cooldownUntil != event.deadline) return;
    emit(state.copyWith(resetCooldownUntil: true));
  }

  void _onIncomingSticker(
    _IncomingStickerReceived event,
    Emitter<BattleStickersState> emit,
  ) {
    final IncomingStickerEntity sticker = event.sticker;
    final String? opponent = _opponentUserId;
    if (sticker.battleId != battleId ||
        opponent == null ||
        opponent.isEmpty ||
        sticker.senderUserId != opponent ||
        sticker.senderUserId == _myUserId) {
      return;
    }
    if (_seenEventIds.contains(sticker.eventId) ||
        _seenSubmissionIds.contains(sticker.submissionId)) {
      return;
    }
    final int? last = _lastSequence;
    if (last != null && sticker.sequence <= last) return;
    // An authentic newer event moves the baseline even when it is not
    // shown (unknown id, hidden, closed phase, stale), so an older event
    // reordered behind it cannot surface later.
    _seenEventIds.add(sticker.eventId);
    _seenSubmissionIds.add(sticker.submissionId);
    _lastSequence = sticker.sequence;
    if (!sticker.stickerId.isKnown ||
        !state.isPhaseAllowed ||
        state.opponentHidden ||
        _isStale(sticker)) {
      return;
    }
    emit(
      state.copyWith(
        opponentBubble: OpponentStickerBubble(
          eventId: sticker.eventId,
          stickerId: sticker.stickerId,
        ),
      ),
    );
    _startBubbleTimer(
      StickerSide.opponent,
      sticker.eventId,
      opponentBubbleDuration,
    );
  }

  /// By the server clock estimate of the battle snapshot, which is always
  /// known here (the opponent is known only after a snapshot).
  bool _isStale(IncomingStickerEntity sticker) =>
      _now().add(_clockOffset).difference(sticker.sentAt) > staleAfter;

  void _onConnectionChanged(
    _StickersConnectionChanged event,
    Emitter<BattleStickersState> emit,
  ) {
    if (event.status == state.connection) return;
    _connectionEpoch++;
    if (event.status == RealtimeStatus.connected) {
      // A new generation: the server may have restarted its sequence.
      // Missed stickers are never requested or replayed.
      _lastSequence = null;
    }
    emit(state.copyWith(connection: event.status));
  }

  void _onOpponentHiddenToggled(
    BattleStickersOpponentHiddenToggled event,
    Emitter<BattleStickersState> emit,
  ) {
    final bool hidden = !state.opponentHidden;
    if (hidden) _opponentBubbleTimer?.cancel();
    emit(state.copyWith(opponentHidden: hidden, resetOpponentBubble: hidden));
  }

  void _onBubbleExpired(
    _StickerBubbleExpired event,
    Emitter<BattleStickersState> emit,
  ) {
    switch (event.side) {
      case StickerSide.own:
        if (state.ownBubble?.submissionId == event.key) {
          emit(state.copyWith(resetOwnBubble: true));
        }
      case StickerSide.opponent:
        if (state.opponentBubble?.eventId == event.key) {
          emit(state.copyWith(resetOpponentBubble: true));
        }
    }
  }

  /// Restarts the display window of [side]'s bubble [key].
  void _startBubbleTimer(StickerSide side, String key, Duration duration) {
    final Timer timer = Timer(duration, () {
      if (!isClosed) add(_StickerBubbleExpired(side: side, key: key));
    });
    switch (side) {
      case StickerSide.own:
        _ownBubbleTimer?.cancel();
        _ownBubbleTimer = timer;
      case StickerSide.opponent:
        _opponentBubbleTimer?.cancel();
        _opponentBubbleTimer = timer;
    }
  }

  @override
  Future<void> close() async {
    _ownBubbleTimer?.cancel();
    _opponentBubbleTimer?.cancel();
    _cooldownTimer?.cancel();
    _retryTimer?.cancel();
    await _stickerSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await super.close();
    // Lets a send waiting for its retry finish; its emitter is done now.
    final Completer<void>? wait = _retryWait;
    if (wait != null && !wait.isCompleted) wait.complete();
  }
}

/// The last [_limit] distinct ids, oldest dropped first.
final class _RecentIds {
  _RecentIds(this._limit);

  final int _limit;
  final Queue<String> _order = Queue<String>();
  final Set<String> _ids = <String>{};

  bool contains(String id) => _ids.contains(id);

  void add(String id) {
    if (!_ids.add(id)) return;
    _order.addLast(id);
    if (_order.length > _limit) _ids.remove(_order.removeFirst());
  }
}
