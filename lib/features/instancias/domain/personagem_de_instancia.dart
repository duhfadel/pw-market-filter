import 'entrada_de_instancia.dart';

/// Um personagem na lista de alguém, com o que ele carrega.
///
/// **Isto não tem nada que ver com o mercado.** Ninguém aqui está à venda:
/// são os personagens de quem está a ler, escritos à mão, e o site nunca os
/// viu nem os pode verificar. É por isso que a classe é escolhida e o nome é
/// escrito — não há de onde os ir buscar.
class PersonagemDeInstancia {
  const PersonagemDeInstancia({
    required this.nome,
    required this.classe,
    this.contagens = const {},
    this.coletadoEm,
    this.extras = const {},
  });

  /// O apelido, como o dono dele o escreve. Pode ser qualquer coisa — este
  /// campo nunca é comparado com nada.
  final String nome;

  /// Uma das dezassete, e serve para desenhar o ícone. É só isso: a
  /// ferramenta não sabe nem precisa de saber o que cada classe faz.
  final String classe;

  /// Quanto ele tem de cada coisa. **Ausente é zero**, e os dois são escritos
  /// iguais na tela — ao contrário do card do mercado, onde `carrega 0` e
  /// *não foi lido* são factos diferentes. Aqui quem escreve é o dono: se não
  /// escreveu nada, tem zero, e não há terceira hipótese.
  final Map<EntradaDeInstancia, int> contagens;

  /// O dia em que se pegou a coleta diária deste personagem pela última vez,
  /// como `AAAA-MM-DD` no fuso do Brasil — ou `null` se nunca.
  ///
  /// **É uma data e não um booleano de propósito.** Um *já pegou* sem data
  /// nunca se apagaria sozinho: amanhã continuaria a dizer que já pegou. A
  /// data compara-se com o dia de hoje e vira *pode pegar* à meia-noite do
  /// Brasil sem ninguém lhe tocar — a mesma razão pela qual o selo *novo* dos
  /// guias carrega uma data em vez de uma bandeira.
  final String? coletadoEm;

  /// O valor de cada campo personalizado, pela `CampoPersonalizado.id`.
  ///
  /// **Por id e nunca por nome**, para o valor sobreviver à renomeação do
  /// campo. O que o texto guardado significa depende do tipo do campo: uma
  /// marcação é `'1'` (ou ausente), uma escolha é a opção escolhida, uma nota
  /// é o próprio texto. Ausente é *não preenchido*.
  final Map<String, String> extras;

  int de(EntradaDeInstancia entrada) => contagens[entrada] ?? 0;

  /// Se a coleta diária já foi feita no dia [hoje].
  bool pegouEm(String hoje) => coletadoEm == hoje;

  /// O valor de um campo personalizado, ou `null` se não preenchido.
  String? extra(String campoId) => extras[campoId];

  /// Se a marcação [campoId] está ligada.
  bool marcado(String campoId) => extras[campoId] == '1';

  PersonagemDeInstancia _copia({
    Map<EntradaDeInstancia, int>? contagens,
    String? nome,
    Object? coletadoEm = _mantem,
    Map<String, String>? extras,
  }) => PersonagemDeInstancia(
    nome: nome ?? this.nome,
    classe: classe,
    contagens: contagens ?? this.contagens,
    coletadoEm: coletadoEm == _mantem ? this.coletadoEm : coletadoEm as String?,
    extras: extras ?? this.extras,
  );

  static const _mantem = Object();

  PersonagemDeInstancia com(EntradaDeInstancia entrada, int quantos) =>
      _copia(contagens: {...contagens, entrada: quantos < 0 ? 0 : quantos});

  PersonagemDeInstancia renomeado(String novo) => _copia(nome: novo);

  /// Define (ou limpa) um campo personalizado. Um valor vazio **apaga** a
  /// chave em vez de guardar uma string vazia: ausente é *não preenchido*, e
  /// uma nota apagada tem de voltar a esse estado, não a um `''` que ainda
  /// contaria como preenchida.
  PersonagemDeInstancia comExtra(String campoId, String? valor) {
    final novos = {...extras};
    if (valor == null || valor.isEmpty) {
      novos.remove(campoId);
    } else {
      novos[campoId] = valor;
    }
    return _copia(extras: novos);
  }

  /// Esquece um campo que foi apagado do plano — para o `extras` não guardar
  /// valores órfãos de um campo que já não existe.
  PersonagemDeInstancia semOCampo(String campoId) {
    if (!extras.containsKey(campoId)) return this;
    final novos = {...extras}..remove(campoId);
    return _copia(extras: novos);
  }

  /// Pega as três entradas do dia: +1 em cada Relíquia Maravilha, e marca
  /// [coletadoEm] como [hoje]. A Chave não entra — a coleta diária dá
  /// entradas, não chaves.
  ///
  /// **Idempotente no dia.** Se já pegou hoje, devolve-se a si próprio sem
  /// somar nada — é o que impede dois cliques de valerem seis entradas, e o
  /// que deixa o botão do grupo passar por quem já pegou sem o penalizar.
  PersonagemDeInstancia comColetaDiaria(String hoje) {
    if (pegouEm(hoje)) return this;
    return _copia(
      contagens: {
        ...contagens,
        for (final e in EntradaDeInstancia.entradas) e: de(e) + 1,
      },
      coletadoEm: hoje,
    );
  }

  /// Finaliza uma dungeon que gasta a entrada [entrada]: −1 nela, +6 na Chave.
  ///
  /// **Só se tiver a entrada.** Quem está a zero daquela não pode fazer a
  /// dungeon, portanto devolve-se a si próprio sem mexer — o que deixa o botão
  /// do grupo passar por quem não pode e contar só quem fez.
  PersonagemDeInstancia comDungeon(EntradaDeInstancia entrada) {
    if (de(entrada) < 1) return this;
    return _copia(
      contagens: {
        ...contagens,
        entrada: de(entrada) - 1,
        EntradaDeInstancia.chave: de(EntradaDeInstancia.chave) + 6,
      },
    );
  }
}
