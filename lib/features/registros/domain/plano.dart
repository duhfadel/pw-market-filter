import 'registro.dart';

/// What the visitor has marked to do, and what it costs.
///
/// Two sums, and both are real quantities.
///
/// **Pages** are one currency: thirty plus forty is seventy. **Attributes**
/// add within themselves — three Atk F plus fifteen Atk F is eighteen Atk F,
/// which is exactly what a character ends up with.
///
/// What is *not* summed, here or anywhere, is one attribute with another. Atk
/// F plus Esquiva was the number taken off the panel, and it stays off: it is
/// not a quantity of anything. The rule is add inside an attribute, never
/// across.
///
/// It exists because the tabs cost wildly different amounts and nothing said
/// so: Área 1 is 32 pages for all thirty-two recipes, and Área 2 is 343 for
/// the same count. Somebody deciding where to start had no way to know.
class Plano {
  const Plano({
    required this.registros,
    required this.paginas,
    required this.pontos,
    required this.semCusto,
  });

  /// How many recipes are marked.
  final int registros;

  /// Pages they cost, adding only the ones whose cost is known.
  final int paginas;

  /// What the marked recipes grant, attribute by attribute.
  ///
  /// In [RegistroAtributo.values] order and not insertion order: a total whose
  /// lines reshuffle when you mark one more is a total nobody can compare
  /// against the one they just read.
  final Map<RegistroAtributo, int> pontos;

  /// How many of the marked have no cost recorded.
  ///
  /// Counted separately and shown, never folded in as zero: a total that
  /// silently omits them reads as complete while being short by an unknown
  /// amount. Admitting the gap is the smaller error.
  final int semCusto;

  bool get vazio => registros == 0;
}

/// The plan for [marcados], read against the recipes that actually exist.
///
/// A mark naming a recipe the table no longer has is dropped rather than
/// counted — a stale state must not inflate the bill.
Plano planoDe(List<Registro> todos, Set<String> marcados) {
  var registros = 0;
  var paginas = 0;
  var semCusto = 0;
  final somas = <RegistroAtributo, int>{};

  for (final registro in todos) {
    if (!marcados.contains(registro.chave)) continue;
    registros++;

    final custo = registro.paginas;
    if (custo == null) {
      semCusto++;
    } else {
      paginas += custo;
    }

    for (final ponto in registro.pontos.entries) {
      somas[ponto.key] = (somas[ponto.key] ?? 0) + ponto.value;
    }
  }

  return Plano(
    registros: registros,
    paginas: paginas,
    // Rebuilt in the enum's order, so the list reads the same way every time.
    pontos: {
      for (final atributo in RegistroAtributo.values)
        if (somas.containsKey(atributo)) atributo: somas[atributo]!,
    },
    semCusto: semCusto,
  );
}
