part of 'battle_stickers_bloc.dart';

/// Which avatar a bubble belongs to.
enum StickerSide { own, opponent }

/// What the own bubble shows. `sending` and `sent` look the same (the
/// animation plays at once); `notSent` is the failed variant.
enum OwnStickerStatus { sending, sent, notSent }

/// The bubble under the own avatar. [submissionId] is also its key, so a
/// later send of the same sticker restarts the animation.
final class OwnStickerBubble extends Equatable {
  const OwnStickerBubble({
    required this.submissionId,
    required this.stickerId,
    required this.status,
  });

  final String submissionId;
  final StickerId stickerId;
  final OwnStickerStatus status;

  OwnStickerBubble copyWith({OwnStickerStatus? status}) => OwnStickerBubble(
    submissionId: submissionId,
    stickerId: stickerId,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => <Object?>[submissionId, stickerId, status];
}

/// The bubble under the opponent's avatar. [eventId] is its key.
final class OpponentStickerBubble extends Equatable {
  const OpponentStickerBubble({required this.eventId, required this.stickerId});

  final String eventId;

  /// Always a known sticker: unknown ids are never shown.
  final StickerId stickerId;

  @override
  List<Object?> get props => <Object?>[eventId, stickerId];
}

final class BattleStickersState extends Equatable {
  const BattleStickersState({
    this.phase,
    this.connection = RealtimeStatus.connecting,
    this.sendingSubmissionId,
    this.cooldownUntil,
    this.serverClosed = false,
    this.ownBubble,
    this.opponentBubble,
    this.opponentHidden = false,
    this.battleRefreshTicket = 0,
  });

  /// `null` until the first battle snapshot.
  final BattlePhase? phase;
  final RealtimeStatus connection;

  /// The intent whose request is in flight; another send waits for it.
  final String? sendingSubmissionId;

  /// Local instant the next send is allowed, derived from the server's
  /// `nextAllowedAt` / `resetsAt`. `null` when no cooldown is known; cleared
  /// by the bloc when it passes.
  final DateTime? cooldownUntil;

  /// The server answered STICKERS_NOT_ALLOWED; sends stay off until the
  /// phase changes.
  final bool serverClosed;
  final OwnStickerBubble? ownBubble;
  final OpponentStickerBubble? opponentBubble;

  /// Local, per battle: incoming stickers are dropped while true.
  final bool opponentHidden;

  /// Increments when the battle must be read again (STICKERS_NOT_ALLOWED,
  /// BATTLE_NOT_FOUND); the screen forwards it to `BattleBloc`.
  final int battleRefreshTicket;

  /// New sends are allowed only in these phases (never after the end).
  bool get isPhaseAllowed => switch (phase) {
    BattlePhase.waitingReady ||
    BattlePhase.countdown ||
    BattlePhase.question ||
    BattlePhase.reveal => true,
    BattlePhase.finished || BattlePhase.cancelled || null => false,
  };

  bool get isSending => sendingSubmissionId != null;

  bool get isCoolingDown => cooldownUntil != null;

  bool get canSend =>
      isPhaseAllowed &&
      !serverClosed &&
      connection == RealtimeStatus.connected &&
      !isSending &&
      !isCoolingDown;

  BattleStickersState copyWith({
    BattlePhase? phase,
    RealtimeStatus? connection,
    String? sendingSubmissionId,
    DateTime? cooldownUntil,
    bool? serverClosed,
    OwnStickerBubble? ownBubble,
    OpponentStickerBubble? opponentBubble,
    bool? opponentHidden,
    int? battleRefreshTicket,
    bool resetSendingSubmissionId = false,
    bool resetCooldownUntil = false,
    bool resetOwnBubble = false,
    bool resetOpponentBubble = false,
  }) {
    return BattleStickersState(
      phase: phase ?? this.phase,
      connection: connection ?? this.connection,
      sendingSubmissionId: resetSendingSubmissionId
          ? null
          : sendingSubmissionId ?? this.sendingSubmissionId,
      cooldownUntil: resetCooldownUntil
          ? null
          : cooldownUntil ?? this.cooldownUntil,
      serverClosed: serverClosed ?? this.serverClosed,
      ownBubble: resetOwnBubble ? null : ownBubble ?? this.ownBubble,
      opponentBubble: resetOpponentBubble
          ? null
          : opponentBubble ?? this.opponentBubble,
      opponentHidden: opponentHidden ?? this.opponentHidden,
      battleRefreshTicket: battleRefreshTicket ?? this.battleRefreshTicket,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    phase,
    connection,
    sendingSubmissionId,
    cooldownUntil,
    serverClosed,
    ownBubble,
    opponentBubble,
    opponentHidden,
    battleRefreshTicket,
  ];
}
