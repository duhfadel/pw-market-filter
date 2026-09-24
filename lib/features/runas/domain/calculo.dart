import 'runa.dart';

/// What somebody still has to find, given what they already own.
///
/// Everything is converted to **level-one runes** and compared there. The
/// ladder divides evenly all the way down — every rung is an whole multiple of
/// the one below — so the common unit loses nothing, and it is the only way a
/// drawer holding three levels at once can be added up at all.
class Calculo {
  const Calculo({required this.alvo, required this.restante});

  final int alvo;

  /// In level-one runes. Never negative: owning more than the target asks for
  /// is not an errand of minus four.
  final int restante;

  bool get jaDa => restante == 0;

  List<int> get escalas => escalasPara(alvo);

  /// How many runes of [nivel] would cover what is left.
  ///
  /// **Rounded up, and the rounding is the honest part.** Two level sevens are
  /// 40% of a level eight, so 4.6 of them are missing — and nobody can find
  /// six tenths of a rune. Five is the errand; the finer scales are where the
  /// leftover is visible.
  int faltaEm(int nivel) {
    final valor = custoEmNivel1(nivel);
    return (restante + valor - 1) ~/ valor;
  }
}

/// [estoque] maps a rune level to how many of it are already owned.
Calculo calcular({required int alvo, required Map<int, int> estoque}) {
  var tem = 0;
  for (final entry in estoque.entries) {
    tem += custoEmNivel1(entry.key) * entry.value;
  }
  final falta = custoEmNivel1(alvo) - tem;
  return Calculo(alvo: alvo, restante: falta < 0 ? 0 : falta);
}
