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

  /// Every level below the target, biggest first.
  ///
  /// The lines are **alternatives**, not a list to add up: each one is the
  /// whole debt written in a different currency, the way the game's own cost
  /// window writes it.
  List<int> get escalas => [for (var n = alvo - 1; n >= 1; n--) n];

  /// The debt in runes of [nivel], with whatever will not divide paid in the
  /// biggest coin below it that fits.
  ///
  /// **Cascading rather than dumping the remainder into level ones**, because
  /// the remainder is an errand: 15.552 level ones and three level sevens are
  /// the same thing, and only one of them is something a person goes and
  /// gets. It is also the shape the game's own lists use.
  List<Parcela> linhaDe(int nivel) {
    final partes = <Parcela>[];
    var falta = restante;
    for (var n = nivel; n >= 1 && falta > 0; n--) {
      final valor = custoEmNivel1(n);
      final quantos = falta ~/ valor;
      if (quantos == 0) continue;
      partes.add(Parcela(nivel: n, quantos: quantos));
      falta -= quantos * valor;
    }
    return partes;
  }

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

/// One term of a line: so many runes of one level.
class Parcela {
  const Parcela({required this.nivel, required this.quantos});

  final int nivel;
  final int quantos;

  @override
  bool operator ==(Object other) =>
      other is Parcela && other.nivel == nivel && other.quantos == quantos;

  @override
  int get hashCode => Object.hash(nivel, quantos);

  @override
  String toString() => '$quantos nv$nivel';
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
