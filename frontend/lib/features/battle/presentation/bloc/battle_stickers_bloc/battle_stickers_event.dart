part of 'battle_stickers_bloc.dart';

sealed class BattleStickersEvent extends Equatable {
  const BattleStickersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Subscribes to BATTLE_STICKER events and the connection status.
final class BattleStickersStarted extends BattleStickersEvent {
  const BattleStickersStarted();
}

/// The battle facts the stickers depend on, forwarded by the screen from
/// every new `BattleBloc` snapshot.
final class BattleStickersBattleUpdated extends BattleStickersEvent {
  const BattleStickersBattleUpdated({
    required this.phase,
    required this.myUserId,
    required this.opponentUserId,
    required this.clockOffset,
  });

  final BattlePhase phase;
  final String myUserId;
  final String opponentUserId;

  /// Server time minus local time (`BattleSnapshotEntity.clockOffset`).
  final Duration clockOffset;

  @override
  List<Object?> get props => <Object?>[
    phase,
    myUserId,
    opponentUserId,
    clockOffset,
  ];
}

/// A tap on a picker cell: plays the own bubble at once and sends it.
final class BattleStickerSendRequested extends BattleStickersEvent {
  const BattleStickerSendRequested(this.stickerId);

  final StickerId stickerId;

  @override
  List<Object?> get props => <Object?>[stickerId];
}

/// Hides (and clears) or shows the opponent's stickers for this battle.
final class BattleStickersOpponentHiddenToggled extends BattleStickersEvent {
  const BattleStickersOpponentHiddenToggled();
}

final class _IncomingStickerReceived extends BattleStickersEvent {
  const _IncomingStickerReceived(this.sticker);

  final IncomingStickerEntity sticker;

  @override
  List<Object?> get props => <Object?>[sticker];
}

final class _StickersConnectionChanged extends BattleStickersEvent {
  const _StickersConnectionChanged(this.status);

  final RealtimeStatus status;

  @override
  List<Object?> get props => <Object?>[status];
}

/// The display window of the bubble [key] ended.
final class _StickerBubbleExpired extends BattleStickersEvent {
  const _StickerBubbleExpired({required this.side, required this.key});

  final StickerSide side;
  final String key;

  @override
  List<Object?> get props => <Object?>[side, key];
}

/// [deadline] passed; clears the cooldown if it is still the current one.
final class _StickerCooldownEnded extends BattleStickersEvent {
  const _StickerCooldownEnded(this.deadline);

  final DateTime deadline;

  @override
  List<Object?> get props => <Object?>[deadline];
}
