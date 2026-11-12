/// As quatro coisas que esta ferramenta conta, e nada mais.
///
/// **São itens do jogo e não ideias nossas**, portanto vivem aqui pelo nome e
/// pelo id da arte — os mesmos quatro que a mochila do filtro já conta
/// (`countedItemGroups`). O que muda é a pergunta: lá é *quem no mercado
/// carrega isto*, aqui é *quanto é que eu tenho, em cada personagem*.
///
/// **Não lê o índice do mercado, de propósito.** Seria uma dependência de
/// 3 MB para saber quatro ids que não mudam, e tornaria um planeador pessoal
/// refém de uma recolha — que, hoje, está parada. Os ids foram lidos do
/// índice uma vez e estão cravados, como `countedItemIcons` já faz.
enum EntradaDeInstancia {
  artefato('Artefato', 'Relíquia Maravilha: Artefato', 54687),
  arma('Arma', 'Relíquia Maravilha: Arma', 50410),
  armadura('Armadura', 'Relíquia Maravilha: Armadura', 70020),

  /// A chave fica por último porque não é uma entrada: é o que se gasta lá
  /// dentro. A ordem da tabela é a ordem desta lista.
  chave('Chave', 'Chave da Sorte', 56274);

  const EntradaDeInstancia(this.curto, this.nome, this.itemId);

  /// O que cabe num cabeçalho de coluna a 390 px. `Relíquia Maravilha:
  /// Artefato` tem 28 caracteres e nenhuma tabela de quatro colunas o
  /// aguenta — o nome inteiro vive no [nome], para quem precisar dele.
  final String curto;

  /// Como o jogo o chama. É por aqui que alguém confere que marcou o item
  /// certo, e é o texto da ajuda de cada coluna.
  final String nome;

  /// O id da arte, em `assets/icons/items/`.
  final int itemId;

  /// As três que abrem a instância — as Relíquia Maravilha. A [chave] fica de
  /// fora: ela não é uma entrada, é o que se gasta lá dentro, e o telemóvel
  /// desenha-a numa linha à parte por isso.
  static const entradas = [artefato, arma, armadura];
}
