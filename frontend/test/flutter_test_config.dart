import 'dart:async';

import 'helpers/load_app_fonts.dart';

/// Loads the bundled fonts before every test file, so layouts are measured
/// with the real glyph widths instead of the test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  await testMain();
}
