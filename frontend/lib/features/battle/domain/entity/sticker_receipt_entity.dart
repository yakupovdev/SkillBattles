import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// The server accepted a sticker send. Acceptance only: it says nothing
/// about delivery to, or display by, the opponent.
final class StickerReceiptEntity extends Equatable {
  const StickerReceiptEntity({
    required this.battleId,
    required this.submissionId,
    required this.senderUserId,
    required this.stickerId,
    required this.sentAt,
    required this.nextAllowedAt,
  });

  final String battleId;
  final String submissionId;
  final String senderUserId;
  final StickerId stickerId;

  /// Server instant of the (original) acceptance.
  final DateTime sentAt;

  /// Server instant the next send is allowed: the original acceptance plus
  /// 4 s. A replayed receipt repeats the original value.
  final DateTime nextAllowedAt;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    submissionId,
    senderUserId,
    stickerId,
    sentAt,
    nextAllowedAt,
  ];
}
