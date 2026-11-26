/// Who someone is in the guild panel. The string on the left is exactly what
/// `perfis.papel` stores in the database — the join key, never translated.
enum Papel {
  admin('admin'),
  staffEditor('staff_editor'),
  staffBasico('staff_basico'),
  salaGuerras('sala_guerras');

  const Papel(this.noBanco);
  final String noBanco;

  /// `null` for an unknown or absent role — an account with no row in `perfis`
  /// has no power, which is not the same as a default role.
  static Papel? doBanco(String? valor) {
    for (final p in Papel.values) {
      if (p.noBanco == valor) return p;
    }
    return null;
  }

  /// The three edit roles may create/edit/remove players this iteration;
  /// `salaGuerras` is for the second piece and touches nothing here.
  bool get podeEditarJogadores => this != Papel.salaGuerras;
}
