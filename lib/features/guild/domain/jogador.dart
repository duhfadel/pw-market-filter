/// A member of the guild, as the panel's roster shows them.
///
/// Every field but `id`, `nome` and `status` is optional, because most of
/// them come from reading a character sheet print by hand and a print that
/// has not been read yet (`status == 'pendente'`) has none of them. A field
/// that is absent means "not informed" — never zero, and never the text
/// "0%" either, the same rule the market index already follows for a
/// counted item nobody has read.
///
/// Some values the sheet prints as a range or with a unit baked in — a
/// critical chance, a fury bar, a channel reduction — and those stay text
/// (`String?`) rather than being parsed into a number that would silently
/// drop the unit or the range.
class Jogador {
  Jogador({
    required this.id,
    required this.nome,
    this.cla,
    this.classe,
    this.cultivo,
    this.limite,
    this.nivel,
    this.despertares,
    this.hp,
    this.mp,
    this.acerto,
    this.nivelAtaque,
    this.ataqueFisico,
    this.ataqueMagico,
    this.furia,
    this.critico,
    this.canalizacao,
    this.defFisica,
    this.defMetal,
    this.defMadeira,
    this.defAgua,
    this.defFogo,
    this.defTerra,
    this.esquiva,
    this.nivelDefesa,
    this.penetracaoFisica,
    this.penetracaoMagica,
    this.espirito,
    this.indiceDano,
    this.sobrevivencia,
    this.printUrl,
    this.recorteRunasUrl,
    this.recorteGearUrl,
    this.nota,
    this.atualizadoPor,
    this.atualizadoEm,
    this.status = 'pendente',
  });

  final String id;
  final String nome;

  final String? cla;
  final String? classe;
  final String? cultivo;
  final String? limite;

  final int? nivel;
  final int? despertares;
  final int? hp;
  final int? mp;
  final int? acerto;
  final int? nivelAtaque;

  final String? ataqueFisico;
  final String? ataqueMagico;
  final String? furia;
  final String? critico;
  final String? canalizacao;

  final int? defFisica;
  final int? defMetal;
  final int? defMadeira;
  final int? defAgua;
  final int? defFogo;
  final int? defTerra;
  final int? esquiva;
  final int? nivelDefesa;
  final int? penetracaoFisica;
  final int? penetracaoMagica;
  final int? espirito;

  final int? indiceDano;
  final int? sobrevivencia;

  final String? printUrl;
  final String? recorteRunasUrl;
  final String? recorteGearUrl;

  final String? nota;
  final String? atualizadoPor;
  final DateTime? atualizadoEm;

  final String status;

  /// Whether the sheet print has been read and this entry's stats are real.
  /// A player stays `pendente` until someone transcribes their print, and
  /// `transcrito` is the only honest way to tell the two states apart.
  bool get transcrito => status == 'transcrito';

  /// Whether this entry has been flagged for a second look.
  bool get aRevisar => status == 'revisar';

  factory Jogador.fromJson(Map<String, dynamic> json) {
    return Jogador(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cla: json['cla'] as String?,
      classe: json['classe'] as String?,
      cultivo: json['cultivo'] as String?,
      limite: json['limite'] as String?,
      nivel: json['nivel'] as int?,
      despertares: json['despertares'] as int?,
      hp: json['hp'] as int?,
      mp: json['mp'] as int?,
      acerto: json['acerto'] as int?,
      nivelAtaque: json['nivel_ataque'] as int?,
      ataqueFisico: json['ataque_fisico'] as String?,
      ataqueMagico: json['ataque_magico'] as String?,
      furia: json['furia'] as String?,
      critico: json['critico'] as String?,
      canalizacao: json['canalizacao'] as String?,
      defFisica: json['def_fisica'] as int?,
      defMetal: json['def_metal'] as int?,
      defMadeira: json['def_madeira'] as int?,
      defAgua: json['def_agua'] as int?,
      defFogo: json['def_fogo'] as int?,
      defTerra: json['def_terra'] as int?,
      esquiva: json['esquiva'] as int?,
      nivelDefesa: json['nivel_defesa'] as int?,
      penetracaoFisica: json['penetracao_fisica'] as int?,
      penetracaoMagica: json['penetracao_magica'] as int?,
      espirito: json['espirito'] as int?,
      indiceDano: json['indice_dano'] as int?,
      sobrevivencia: json['sobrevivencia'] as int?,
      printUrl: json['print_url'] as String?,
      recorteRunasUrl: json['recorte_runas_url'] as String?,
      recorteGearUrl: json['recorte_gear_url'] as String?,
      nota: json['nota'] as String?,
      atualizadoPor: json['atualizado_por'] as String?,
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'] as String)
          : null,
      status: json['status'] as String? ?? 'pendente',
    );
  }

  /// Omits every null field — writing them would assert "zero" or "empty"
  /// about a stat nobody has read yet, the same rule the market index
  /// follows for an attribute a conduit does not carry.
  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    void put(String k, Object? v) {
      if (v != null) m[k] = v;
    }

    put('id', id);
    m['nome'] = nome;
    put('cla', cla);
    put('classe', classe);
    put('cultivo', cultivo);
    put('limite', limite);
    put('nivel', nivel);
    put('despertares', despertares);
    put('hp', hp);
    put('mp', mp);
    put('acerto', acerto);
    put('nivel_ataque', nivelAtaque);
    put('ataque_fisico', ataqueFisico);
    put('ataque_magico', ataqueMagico);
    put('furia', furia);
    put('critico', critico);
    put('canalizacao', canalizacao);
    put('def_fisica', defFisica);
    put('def_metal', defMetal);
    put('def_madeira', defMadeira);
    put('def_agua', defAgua);
    put('def_fogo', defFogo);
    put('def_terra', defTerra);
    put('esquiva', esquiva);
    put('nivel_defesa', nivelDefesa);
    put('penetracao_fisica', penetracaoFisica);
    put('penetracao_magica', penetracaoMagica);
    put('espirito', espirito);
    put('indice_dano', indiceDano);
    put('sobrevivencia', sobrevivencia);
    put('print_url', printUrl);
    put('recorte_runas_url', recorteRunasUrl);
    put('recorte_gear_url', recorteGearUrl);
    put('nota', nota);
    put('atualizado_por', atualizadoPor);
    put('atualizado_em', atualizadoEm?.toIso8601String());
    m['status'] = status;
    return m;
  }

  /// A copy carrying the storage path returned by the upload. Every other
  /// field is preserved — the upload only learns the print's path.
  Jogador comPrintUrl(String url) => Jogador(
    id: id,
    nome: nome,
    cla: cla,
    classe: classe,
    cultivo: cultivo,
    limite: limite,
    nivel: nivel,
    despertares: despertares,
    hp: hp,
    mp: mp,
    acerto: acerto,
    nivelAtaque: nivelAtaque,
    ataqueFisico: ataqueFisico,
    ataqueMagico: ataqueMagico,
    furia: furia,
    critico: critico,
    canalizacao: canalizacao,
    defFisica: defFisica,
    defMetal: defMetal,
    defMadeira: defMadeira,
    defAgua: defAgua,
    defFogo: defFogo,
    defTerra: defTerra,
    esquiva: esquiva,
    nivelDefesa: nivelDefesa,
    penetracaoFisica: penetracaoFisica,
    penetracaoMagica: penetracaoMagica,
    espirito: espirito,
    indiceDano: indiceDano,
    sobrevivencia: sobrevivencia,
    printUrl: url,
    recorteRunasUrl: recorteRunasUrl,
    recorteGearUrl: recorteGearUrl,
    nota: nota,
    atualizadoPor: atualizadoPor,
    atualizadoEm: atualizadoEm,
    status: status,
  );
}
