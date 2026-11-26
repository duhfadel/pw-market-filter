import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'imagem_escolhida.dart';

/// Opens a native `<input type=file>` and reads the picked file's bytes.
/// Browser-only — never imported on the VM, where `escolher_imagem_io.dart`
/// stands in instead.
Future<ImagemEscolhida?> escolherImagem() async {
  final input =
      (web.document.createElement('input') as web.HTMLInputElement)
        ..type = 'file'
        ..accept = 'image/*';
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.length == 0) return null;
  final file = files.item(0)!;
  final buffer = await file.arrayBuffer().toDart;
  return ImagemEscolhida(buffer.toDart.asUint8List(), file.name);
}
