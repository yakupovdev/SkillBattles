import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// Reads and parses one Lottie file. Replaceable in tests.
typedef StickerCompositionLoader = Future<LottieComposition> Function(
  String assetPath,
);

/// The nine parsed sticker compositions, loaded once and reused for every
/// bubble and picker cell (nothing is fetched or parsed per send).
///
/// Owned by `StickerCompositionsScope`; [ensureLoaded] is idempotent.
/// A file that fails to load or parse is simply missing: the view shows the
/// sticker name instead and the sticker stays sendable.
final class StickerCompositions extends ChangeNotifier {
  StickerCompositions({StickerCompositionLoader? loader})
    : _load = loader ?? _loadAsset;

  final StickerCompositionLoader _load;
  final Map<StickerId, LottieComposition> _compositions =
      <StickerId, LottieComposition>{};
  Future<void>? _loading;
  bool _isReady = false;
  bool _isDisposed = false;

  static Future<LottieComposition> _loadAsset(String path) =>
      AssetLottie(path).load();

  /// `assets/stickers/<wireId>.json`.
  static String assetOf(StickerId id) => 'assets/stickers/${id.wireId}.json';

  /// All nine files were attempted (some may have failed).
  bool get isReady => _isReady;

  /// `null` when the file is not loaded yet or failed to parse.
  LottieComposition? compositionOf(StickerId id) => _compositions[id];

  Future<void> ensureLoaded() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    await Future.wait(<Future<void>>[
      for (final StickerId id in StickerId.supported) _loadOne(id),
    ]);
    _isReady = true;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _loadOne(StickerId id) async {
    try {
      _compositions[id] = await _load(assetOf(id));
    } on Object catch (error, stackTrace) {
      // A broken asset must never block the picker; the view falls back to
      // the sticker name. The parser may throw an Error for a malformed
      // file, so Errors are caught here too (asset data, not app logic).
      developer.log(
        'Sticker ${id.wireId} failed to load',
        name: 'stickers',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
