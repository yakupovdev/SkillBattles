import 'dart:io';

import 'package:flutter/services.dart';

/// Registers the bundled Paper fonts with the test engine.
///
/// Widget tests render with the Ahem test font by default, which is far
/// wider than the real fonts and would overflow layouts that fit in the app.
/// The files are read from `assets/fonts` (tests run from the package root).
Future<void> loadAppFonts() async {
  const Map<String, List<String>> families = <String, List<String>>{
    'SpaceGrotesk': <String>[
      'SpaceGrotesk-Regular.ttf',
      'SpaceGrotesk-Medium.ttf',
      'SpaceGrotesk-SemiBold.ttf',
      'SpaceGrotesk-Bold.ttf',
    ],
    'Inter': <String>[
      'Inter-Regular.ttf',
      'Inter-Medium.ttf',
      'Inter-SemiBold.ttf',
      'Inter-Bold.ttf',
    ],
    'JetBrainsMono': <String>[
      'JetBrainsMono-Regular.ttf',
      'JetBrainsMono-Medium.ttf',
      'JetBrainsMono-SemiBold.ttf',
    ],
  };

  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String file in family.value) {
      final List<int> bytes = await File('assets/fonts/$file').readAsBytes();
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    }
    await loader.load();
  }
}
