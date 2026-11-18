import 'dart:convert';
import 'dart:developer' as developer;

import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// Reads one Lottie file and returns its raw JSON text. Replaceable in tests.
typedef StickerCompositionLoader = Future<String> Function(String assetPath);

/// The nine sticker compositions, loaded once and reused for every bubble
/// and picker cell (nothing is fetched per send).
///
/// Holds the raw JSON text of each file: lottie-web mutates the data it is
/// given, so every player parses its own copy (see `LottiePlayer`).
///
/// Owned by `StickerCompositionsScope`; [ensureLoaded] is idempotent.
/// A file that fails to load or parse is simply missing: the view shows the
/// sticker name instead and the sticker stays sendable.
final class StickerCompositions extends ChangeNotifier {
  StickerCompositions({StickerCompositionLoader? loader}) : _load = loader ?? _loadAsset;

  final StickerCompositionLoader _load;
  final Map<StickerId, String> _compositions = <StickerId, String>{};
  Future<void>? _loading;
  bool _isReady = false;
  bool _isDisposed = false;

  static Future<String> _loadAsset(String path) async {
    final web.Response response = await web.window.fetch(path.toJS).toDart;
    if (!response.ok) {
      throw StateError('HTTP ${response.status} for $path');
    }
    return (await response.text().toDart).toDart;
  }

  /// `assets/stickers/<wireId>.json`.
  static String assetOf(StickerId id) => 'assets/stickers/${id.wireId}.json';

  /// All nine files were attempted (some may have failed).
  bool get isReady => _isReady;

  /// The raw Lottie JSON; `null` when the file is not loaded yet or failed.
  String? compositionOf(StickerId id) => _compositions[id];

  Future<void> ensureLoaded() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    await Future.wait(<Future<void>>[for (final StickerId id in StickerId.supported) _loadOne(id)]);
    _isReady = true;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _loadOne(StickerId id) async {
    try {
      final String text = await _load(assetOf(id));
      // Only a JSON object is a Lottie composition; anything else would
      // leave an empty player behind.
      if (jsonDecode(text) is! Map<String, Object?>) {
        throw FormatException('Not a Lottie composition', assetOf(id));
      }
      _compositions[id] = text;
    } on Object catch (error, stackTrace) {
      // A broken asset must never block the picker; the view falls back to
      // the sticker name. Errors are caught too (asset data, not app logic).
      developer.log('Sticker ${id.wireId} failed to load', name: 'stickers', error: error, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
