/// One of the seven numbers a registry can raise.
///
/// The short label is what fits on a chip in the grid; the long one names the
/// thing in the filter, where there is room and where "Atk F" would be jargon
/// to somebody who has not opened the NPC yet.
enum RegistroAtributo {
  atkF('atk_f', 'Atk F', 'Ataque Físico'),
  atkM('atk_m', 'Atk M', 'Ataque Mágico'),
  defF('def_f', 'Def F', 'Defesa Física'),
  defM('def_m', 'Def M', 'Defesa Mágica'),
  acerto('acerto', 'Acerto', 'Acerto'),
  esquiva('esquiva', 'Esquiva', 'Esquiva'),
  hp('hp', 'HP', 'HP');

  const RegistroAtributo(this.coluna, this.curto, this.longo);

  /// The column in the `registros` table.
  final String coluna;

  final String curto;
  final String longo;
}

/// The tabs, in the order the NPC's window draws them.
///
/// Written down rather than read off the data, because the order is the
/// window's and not the table's — sorting by name would put Área 2 before
/// Coletar correctly and Casal before Área 1 wrongly, and a grid that does not
/// match the game is a grid nobody can follow while playing.
const abasDoNpc = ['Área 1', 'Área 2', 'Coletar', 'Avançado', 'M/A', 'Casal'];

/// One recipe: one slot in the grid.
class Registro {
  const Registro({
    required this.aba,
    required this.ordem,
    required this.nome,
    required this.paginas,
    required this.semDados,
    required this.pontos,
  });

  final String aba;

  /// **Which slot it occupies**, from 1, counting left to right and top to
  /// bottom across a grid eight wide.
  ///
  /// The slot and not "the nth recipe", and the difference is the whole
  /// layout: the NPC breaks a row when a group ends, so Coletar draws 8, 2
  /// and 6 with slots 11 to 16 left empty, and Avançado skips an entire row.
  /// Read as a running count, every icon after the first row landed in the
  /// wrong place.
  ///
  /// A gap is therefore a number nobody claims, never a neighbour shifted
  /// left.
  final int ordem;

  final String nome;

  /// How many Páginas de Registro: Assimilação it costs. `null` where the
  /// source never recorded one — and not `0`, which would read as free.
  final int? paginas;

  /// Nobody has recorded what this recipe grants.
  ///
  /// Different from granting nothing, and the screen says different things
  /// about them. Seven zeros would have the site assert that marriage gives no
  /// attribute, which is a claim nobody has checked.
  final bool semDados;

  /// Only the attributes it actually raises.
  ///
  /// The zeros are dropped on the way in: the panel prints what a recipe
  /// gives, and a line reading `Def F 0` is noise that pushes the real numbers
  /// off a phone.
  final Map<RegistroAtributo, int> pontos;

  factory Registro.fromJson(Map<String, dynamic> json) => Registro(
    aba: (json['aba'] as String?) ?? '',
    ordem: (json['ordem'] as num?)?.toInt() ?? 0,
    nome: (json['nome'] as String?) ?? '',
    paginas: (json['paginas'] as num?)?.toInt(),
    semDados: json['sem_dados'] == true,
    pontos: {
      for (final atributo in RegistroAtributo.values)
        if (((json[atributo.coluna] as num?)?.toInt() ?? 0) > 0)
          atributo: (json[atributo.coluna] as num).toInt(),
    },
  );
}

/// The recipes of one tab, in the slot order the NPC uses.
List<Registro> ordenados(List<Registro> registros) =>
    [...registros]..sort((a, b) => a.ordem.compareTo(b.ordem));

/// Which tabs these rows cover, in the window's order.
///
/// A tab the list does not know about goes to the end rather than being
/// dropped: a row added to the table before this file hears about it must
/// still reach the screen. Silently discarding it is how a table grows a hole
/// nobody notices.
List<String> abasDe(List<Registro> registros) {
  final presentes = {for (final r in registros) r.aba};
  return [
    ...abasDoNpc.where(presentes.contains),
    ...presentes.where((a) => !abasDoNpc.contains(a)),
  ];
}

/// How many rows of eight a tab needs to show every slot it uses.
///
/// Measured from the **last occupied** slot, so a trailing empty row is not
/// drawn: the game always frames four, and copying an empty one is fidelity
/// to the furniture rather than to the layout — on a phone it is a screen of
/// nothing. A gap *between* rows is different and is kept, because that one
/// moves every icon after it.
int linhasDaGrade(List<int> ocupados) {
  if (ocupados.isEmpty) return 0;
  final ultimo = ocupados.reduce((a, b) => a > b ? a : b);
  return (ultimo + colunasDaGrade - 1) ~/ colunasDaGrade;
}

/// Eight, which is what the NPC's window uses.
const colunasDaGrade = 8;

/// The tab laid out as the game lays it: one entry per slot, `null` where the
/// window shows an empty frame.
List<Registro?> emSlots(List<Registro> daAba) {
  final linhas = linhasDaGrade([for (final r in daAba) r.ordem]);
  final celulas = List<Registro?>.filled(linhas * colunasDaGrade, null);

  for (final registro in daAba) {
    final i = registro.ordem - 1;
    // A slot number past the grid would silently vanish; better to widen the
    // grid than to lose a recipe nobody can see is missing.
    if (i >= 0 && i < celulas.length) celulas[i] = registro;
  }
  return celulas;
}
