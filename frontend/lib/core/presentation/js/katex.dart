import 'package:universal_web/js_interop.dart';

/// Renders TeX to HTML with KaTeX (`web/vendor/katex`, loaded by
/// `main.server.dart`). Returns `null` when KaTeX is not loaded or the formula
/// does not parse, so the caller can show the source instead.
String? renderTex(String tex, {required bool displayMode}) {
  final _Katex? katex = _katexGlobal;
  if (katex == null) return null;
  try {
    return katex.renderToString(
      tex,
      _KatexOptions(displayMode: displayMode, throwOnError: true),
    );
  } on Object {
    return null;
  }
}

@JS('katex')
external _Katex? get _katexGlobal;

extension type _Katex._(JSObject _) implements JSObject {
  external String renderToString(String tex, _KatexOptions options);
}

extension type _KatexOptions._(JSObject _) implements JSObject {
  external factory _KatexOptions({bool displayMode, bool throwOnError});
}
