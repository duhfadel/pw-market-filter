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
  List<Parcela> linhaDe(int nivel) => _cascata(restante, nivel);

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

/// The biggest rune a drawer can be fused into, and what is left after it.
class Forja {
  const Forja({
    required this.nivel,
    required this.quantos,
    required this.sobra,
  });

  /// `null` when the drawer is empty. Never above [nivelMaximo]: twice what a
  /// level 10 costs is two level 10s, not a level 11.
  final int? nivel;

  /// **How many of it, and counting them is not a flourish.** Answering "one
  /// level 4" while another whole level 4 sat in the leftover told the truth
  /// in the most awkward way available: the drawer makes two, and that is
  /// what somebody wants to hear.
  final int quantos;

  /// What is left after all of them, in level-one runes.
  final int sobra;

  /// Whether the drawer can climb at all.
  ///
  /// Two level ones cannot become anything — a level 2 wants three — and the
  /// screen has to say so rather than dress up what is already in the bag as
  /// an achievement.
  bool get daParaFundir => nivel != null && nivel! > 1;

  /// The leftover in whole runes, biggest coin first.
  List<Parcela> get parcelasDaSobra => _cascata(sobra, nivelMaximo);
}

/// The biggest rune [estoque] can become.
///
/// **It answers in levels, not in fusions.** Two level ones are a level 1 and
/// a spare — the drawer cannot climb, and saying so plainly beats inventing
/// an upgrade that is not there.
Forja maiorQueDa(Map<int, int> estoque) {
  var total = 0;
  for (final entry in estoque.entries) {
    total += custoEmNivel1(entry.key) * entry.value;
  }
  if (total == 0) {
    return const Forja(nivel: null, quantos: 0, sobra: 0);
  }

  var maior = 1;
  for (var n = nivelMaximo; n >= 1; n--) {
    if (custoEmNivel1(n) <= total) {
      maior = n;
      break;
    }
  }
  final valor = custoEmNivel1(maior);
  return Forja(nivel: maior, quantos: total ~/ valor, sobra: total % valor);
}

/// So many whole runes of the biggest levels that fit, down from [apartirDe].
List<Parcela> _cascata(int valor, int apartirDe) {
  final partes = <Parcela>[];
  var falta = valor;
  for (var n = apartirDe; n >= 1 && falta > 0; n--) {
    final quantos = falta ~/ custoEmNivel1(n);
    if (quantos == 0) continue;
    partes.add(Parcela(nivel: n, quantos: quantos));
    falta -= quantos * custoEmNivel1(n);
  }
  return partes;
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
