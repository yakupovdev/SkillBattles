import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// Tone of a sticker, shown in the picker footer and the semantics label.
enum StickerCategory {
  emotion('Emotion'),
  taunt('Taunt');

  const StickerCategory(this.label);

  final String label;
}

/// English names and categories of the stickers (Paper: "31 Battle
/// stickers — Sticker set").
extension StickerLabels on StickerId {
  String get label => switch (this) {
    StickerId.gg => 'GG',
    StickerId.fire => 'On fire',
    StickerId.facepalm => 'Facepalm',
    StickerId.lol => 'LOL',
    StickerId.hmm => 'Hmm…',
    StickerId.tooSlow => 'Too slow',
    StickerId.ez => 'Ez',
    StickerId.waitWhat => 'Wait, what?',
    StickerId.crying => 'Crying',
    StickerId.unknown => '',
  };

  StickerCategory get category => switch (this) {
    StickerId.gg ||
    StickerId.fire ||
    StickerId.hmm ||
    StickerId.waitWhat ||
    StickerId.crying ||
    StickerId.unknown => StickerCategory.emotion,
    StickerId.facepalm ||
    StickerId.lol ||
    StickerId.tooSlow ||
    StickerId.ez => StickerCategory.taunt,
  };

  /// `LOL, taunt`.
  String get semanticLabel => '$label, ${category.label.toLowerCase()}';
}
