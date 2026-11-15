/// A battle sticker by its wire id (`stickerId` in the API).
///
/// [unknown] stands for an incoming id this client does not know (a newer
/// backend may add stickers); it is never sent and never shown.
enum StickerId {
  gg('gg'),
  fire('fire'),
  facepalm('facepalm'),
  lol('lol'),
  hmm('hmm'),
  tooSlow('too_slow'),
  ez('ez'),
  waitWhat('wait_what'),
  crying('crying'),
  unknown('');

  const StickerId(this.wireId);

  /// Exact lowercase API id; no aliases, no case folding.
  final String wireId;

  /// Every sticker this client can send, in wire-list order.
  static const List<StickerId> supported = <StickerId>[
    gg,
    fire,
    facepalm,
    lol,
    hmm,
    tooSlow,
    ez,
    waitWhat,
    crying,
  ];

  bool get isKnown => this != unknown;

  /// [unknown] for any value that is not exactly a supported wire id.
  static StickerId fromWire(String value) {
    for (final StickerId id in supported) {
      if (id.wireId == value) return id;
    }
    return unknown;
  }
}
