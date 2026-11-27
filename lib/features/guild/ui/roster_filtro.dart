import '../domain/jogador.dart';

/// The numeric columns the roster table can be sorted by. Each one is a
/// `int?` on [Jogador] except [critico], which the sheet prints as text with
/// a unit baked in (`"74%"`) — the number inside it is what sorts.
enum OrdemColuna { nivelAtaque, hp, nivelDefesa, critico }

/// A pure filter and sort over the roster — no Flutter import anywhere, so
/// the whole thing is testable without pumping a widget.
///
/// The three narrowing fields (`busca`, `classe`, `status`) stack as an
/// *and*, the same rule the Registros filter already follows: a player has
/// to pass every one of them to stay on screen. [ordem], when set, is always
/// descending — there is no ascending direction, because *who has less* is
/// read at the bottom of the same list, not by flipping the arrow.
class RosterFiltro {
  const RosterFiltro({this.busca = '', this.classe, this.status, this.ordem});

  /// Matched against [Jogador.nome], case-insensitively and by substring —
  /// never an exact match, since a search field is for typing a few letters
  /// and seeing who is left.
  final String busca;

  /// Exact match against [Jogador.classe]. Null means every class passes.
  final String? classe;

  /// Exact match against [Jogador.status]. Null means every status passes.
  final String? status;

  /// The column to sort by, descending, with rows that carry no value for it
  /// (a `pendente` or `revisar` entry nobody has transcribed yet) pushed to
  /// the end. Null leaves the list in whatever order it arrived.
  final OrdemColuna? ordem;

  RosterFiltro comBusca(String busca) =>
      RosterFiltro(busca: busca, classe: classe, status: status, ordem: ordem);

  RosterFiltro comClasse(String? classe) =>
      RosterFiltro(busca: busca, classe: classe, status: status, ordem: ordem);

  RosterFiltro comStatus(String? status) =>
      RosterFiltro(busca: busca, classe: classe, status: status, ordem: ordem);

  RosterFiltro comOrdem(OrdemColuna? ordem) =>
      RosterFiltro(busca: busca, classe: classe, status: status, ordem: ordem);

  /// Applies busca, classe and status in sequence, then sorts. The input
  /// list is never mutated.
  List<Jogador> aplicar(List<Jogador> jogadores) {
    var resultado = jogadores;

    final q = busca.trim().toLowerCase();
    if (q.isNotEmpty) {
      resultado = resultado.where((j) => j.nome.toLowerCase().contains(q)).toList();
    }

    if (classe != null) {
      resultado = resultado.where((j) => j.classe == classe).toList();
    }

    if (status != null) {
      resultado = resultado.where((j) => j.status == status).toList();
    }

    final ord = ordem;
    if (ord != null) {
      // Decorate with the original index for a stable sort — `List.sort`
      // makes no stability guarantee, and two players tied on the column
      // (two nulls, or the same number) must not shuffle on every rebuild.
      final indexado = resultado.indexed.toList()
        ..sort((a, b) {
          final va = _valor(a.$2, ord);
          final vb = _valor(b.$2, ord);
          if (va == null && vb == null) return a.$1.compareTo(b.$1);
          if (va == null) return 1;
          if (vb == null) return -1;
          final cmp = vb.compareTo(va); // descending
          return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
        });
      resultado = [for (final par in indexado) par.$2];
    }

    return resultado;
  }

  num? _valor(Jogador j, OrdemColuna ord) => switch (ord) {
    OrdemColuna.nivelAtaque => j.nivelAtaque,
    OrdemColuna.hp => j.hp,
    OrdemColuna.nivelDefesa => j.nivelDefesa,
    OrdemColuna.critico => _numeroEmbutido(j.critico),
  };

  /// Pulls the number out of a text field that bakes in a unit — `"74%"` →
  /// `74`. Null, or a string with no digit at all, sorts with the rest of
  /// the unread rows.
  num? _numeroEmbutido(String? texto) {
    if (texto == null) return null;
    final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(texto);
    return m == null ? null : num.tryParse(m.group(0)!);
  }
}
