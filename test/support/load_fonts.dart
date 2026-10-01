import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the real fonts into the test binding so a widget test measures the
/// same text `flutter run` would.
///
/// `flutter_test` otherwise renders every glyph as a square of the font
/// size, which fabricates overflows no browser ever sees and hides overflows
/// a browser would. Shrinking a layout to silence one of those is treating a
/// harness artefact as a bug in the app — see the note above `_linha` in
/// `ao_vivo_strip.dart` for a case where a measured, real-font number was the
/// whole reason a line was changed.
///
/// [Marcellus] ships as a repository asset and loads through `rootBundle`.
/// Roboto does not — Flutter's Material defaults pull it from the engine's
/// own cache rather than bundling a copy — so it is read straight off disk,
/// derived from [Platform.resolvedExecutable]: `flutter test` runs on the
/// `dart` binary at `<flutter root>/bin/cache/dart-sdk/bin/dart`, five
/// directories below the SDK root that also holds
/// `bin/cache/artifacts/material_fonts`.
Future<void> loadAppFonts() async {
  await _loadAsset('Marcellus', 'assets/fonts/Marcellus-Regular.ttf');

  final robotoPath = _materialFontsDir().resolve('Roboto-Regular.ttf');
  final bytes = await File.fromUri(robotoPath).readAsBytes();
  await _register('Roboto', bytes);
}

Future<void> _loadAsset(String family, String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  await _register(family, bytes.buffer.asUint8List());
}

Future<void> _register(String family, Uint8List bytes) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

/// `<flutter root>/bin/cache/artifacts/material_fonts/`.
Uri _materialFontsDir() {
  final dartExe = Uri.file(Platform.resolvedExecutable);
  // dart-sdk/bin/dart -> dart-sdk/bin -> dart-sdk -> cache -> bin -> <root>
  final flutterRoot = dartExe
      .resolve('../') // dart-sdk/bin/
      .resolve('../') // dart-sdk/
      .resolve('../') // cache/
      .resolve('../') // bin/
      .resolve('../'); // <flutter root>/
  return flutterRoot.resolve('bin/cache/artifacts/material_fonts/');
}
