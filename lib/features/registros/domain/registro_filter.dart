import 'registro.dart';

/// What the screen is asking of the table.
///
/// Two things and no more: which tab is open, and which attributes matter.
///
/// There was a third — an ordering by points per page — and it is gone on the
/// owner's call, with the idea kept for later. It broke the grid's fidelity to
/// the game by construction, since anything that moves a slot stops the grid
/// from being the window; and it ranked recipes by a sum of Atk F and Esquiva,
/// which is not a quantity of anything.
class RegistroQuery {
  const RegistroQuery({this.aba, this.atributos = const {}});

  /// `null` before the data arrives and names the first tab.
  final String? aba;

  /// An **and**: Esquiva and Acerto together keeps only what grants both.
  ///
  /// It was an or at first and that was backwards — ticking a second box lit
  /// *more* slots, so the filter appeared to run in reverse. Both is the
  /// question somebody building a character actually asks.
  ///
  /// It only works because [atributosDisponiveis] never offers a box that
  /// would empty the grid: an and with free choice is how a form leads
  /// somebody to zero results with no hint which tick did it.
  final Set<RegistroAtributo> atributos;

  bool get pedeAlgo => atributos.isNotEmpty;

  RegistroQuery copyWith({String? aba, Set<RegistroAtributo>? atributos}) =>
      RegistroQuery(
        aba: aba ?? this.aba,
        atributos: atributos ?? this.atributos,
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
  return query.atributos.every(registro.pontos.containsKey);
}

/// The slots of one tab, always in the NPC's slot order.
///
/// Always, now. The grid exists to be the game's window, and anything that
/// moves a slot stops it being that.
List<Registro> paraGrade(List<Registro> todos, RegistroQuery query) =>
    ordenados([
      for (final r in todos)
        if (r.aba == query.aba) r,
    ]);

/// Which attributes can still be ticked without emptying the grid.
///
/// The same rule every control on the market's filter follows: offer what
/// still leads somewhere. With an **and** this stops being a nicety — free
/// choice over an and is how a form walks somebody into zero results with no
/// hint which tick did it.
///
/// [daAba] is the open tab and not the whole table, because the grid shows one
/// tab: an option that lights something three tabs away is a dead end on the
/// screen the visitor is looking at.
///
/// What is already ticked stays offered whatever it does to the count.
/// Otherwise the box that emptied the grid would be the one box nobody can
/// untick — the trap, not the way out.
Set<RegistroAtributo> atributosDisponiveis(
  List<Registro> daAba,
  RegistroQuery query,
) {
  final passam = [
    for (final r in daAba)
      if (atende(r, query)) r,
  ];

  return {
    ...query.atributos,
    for (final atributo in RegistroAtributo.values)
      if (passam.any((r) => r.pontos.containsKey(atributo))) atributo,
  };
}
