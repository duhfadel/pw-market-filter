import 'dart:typed_data';

/// A file the staff picked: its bytes and original name (the name carries the
/// extension, which the upload path reuses).
class ImagemEscolhida {
  const ImagemEscolhida(this.bytes, this.nome);
  final Uint8List bytes;
  final String nome;
}
