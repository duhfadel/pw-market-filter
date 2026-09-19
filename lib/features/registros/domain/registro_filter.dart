import 'registro.dart';

/// What the screen is asking of the table.
///
/// Two things and no more: which tab is open, and which attributes matter.
/// The ordering is here too because it changes which slot sits where, which
/// is the one control that breaks the grid's fidelity to the game — so it
/// belongs with the question, not with the drawing.
class RegistroQuery {
  const RegistroQuery({
    this.aba,
    this.atributos = const {},
    this.porAproveitamento = false,
  });

  /// `null` before the data arrives and names the first tab.
  final String? aba;

  /// An **or**: turning on Esquiva and Acerto keeps whatever grants either.
  ///
  /// An and would be the wrong question — a visitor looking for evasion wants
  /// the recipes that give it, not the ones that give it *together with*
  /// something else they happened to tick.
  final Set<RegistroAtributo> atributos;

  /// Sort by points per page instead of by the NPC's slot order.
  final bool porAproveitamento;

  bool get pedeAlgo => atributos.isNotEmpty;

  RegistroQuery copyWith({
    String? aba,
    Set<RegistroAtributo>? atributos,
    bool? porAproveitamento,
  }) => RegistroQuery(
    aba: aba ?? this.aba,
    atributos: atributos ?? this.atributos,
    porAproveitamento: porAproveitamento ?? this.porAproveitamento,
  );
}

/// Whether a slot is lit under the current filter.
///
/// **Lit, not present.** The filter dims slots rather than removing them,
/// because the grid's shape and positions are the whole reason it is a grid
/// and not a list: a player looking at the game window has to find the same
/// slot in the same place. Removing slots would reflow it into something that
/// no longer matches what is on their screen.
bool atende(Registro registro, RegistroQuery query) {
  if (!query.pedeAlgo) return true;
  return query.atributos.any(registro.pontos.containsKey);
}

/// The slots of one tab, in the order the screen should draw them.
List<Registro> paraGrade(List<Registro> todos, RegistroQuery query) {
  final daAba = [
    for (final r in todos)
      if (r.aba == query.aba) r,
  ];

  if (!query.porAproveitamento) return ordenados(daAba);

  // Best trade first. A recipe with no rate — no cost recorded, or nobody has
  // read it — sinks to the end rather than sorting as the worst in the game,
  // which would be a verdict on a blank row.
  return [...daAba]..sort((a, b) {
    final x = a.porPagina, y = b.porPagina;
    if (x == null && y == null) return a.ordem.compareTo(b.ordem);
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  });
}
