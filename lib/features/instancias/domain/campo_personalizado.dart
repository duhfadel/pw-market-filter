/// Que tipo de campo o utilizador criou.
///
/// **Três, e cada um resolve um feitio de informação diferente.** A marcação
/// é um sim/não que se compara entre personagens (*quem fez a TW*); a escolha
/// é uma etiqueta entre opções que o dono define (*Ativo / Vendendo*); a nota
/// é texto livre, que não se compara nem se soma e por isso vive numa linha
/// própria.
enum CampoTipo {
  marcacao('c'),
  escolha('e'),
  nota('t');

  const CampoTipo(this.sigla);

  /// Uma letra, para o link não gastar a palavra inteira em cada campo.
  final String sigla;

  static CampoTipo? daSigla(String s) {
    for (final t in values) {
      if (t.sigla == s) return t;
    }
    return null;
  }
}

/// Um campo que o utilizador inventou — uma coluna de informação que a
/// ferramenta não previu.
///
/// **É global ao plano e não a um personagem.** Criar o campo *TW?* uma vez
/// põe-no em todos, para a marcação ser comparável entre eles — é isso que
/// permite responder *quantos fizeram a TW*. O valor é que é por personagem,
/// guardado em `PersonagemDeInstancia.extras` pela [id] deste campo.
///
/// **A identidade é a [id] e nunca o nome.** O nome muda quando o dono o
/// corrige, e se os valores apontassem para o nome perder-se-iam na primeira
/// renomeação — a mesma razão pela qual um atributo do mercado viaja pela id
/// e não pela posição.
class CampoPersonalizado {
  const CampoPersonalizado({
    required this.id,
    required this.nome,
    required this.tipo,
    this.opcoes = const [],
  });

  /// Um código curto e estável, gerado à criação. Curto porque entra no link
  /// uma vez por valor preenchido.
  final String id;

  final String nome;
  final CampoTipo tipo;

  /// As opções, só para [CampoTipo.escolha]. Vazio nos outros.
  final List<String> opcoes;

  CampoPersonalizado renomeado(String novo) =>
      CampoPersonalizado(id: id, nome: novo, tipo: tipo, opcoes: opcoes);
}
