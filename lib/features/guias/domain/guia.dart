/// Os guias do Portal, declarados num lugar só.
///
/// **Já houve duas listas de guias que não sabiam uma da outra**, e custou:
/// o guia das runas foi publicado e durante dias não havia caminho nenhum
/// para ele a partir do site, porque os artigos viviam em
/// `web/guias/index.html` e o menu vivia em `tool.dart`. Esta lista é a
/// fonte das duas — a página `/guias/` é gerada daqui por
/// `tool/guias/pagina.dart`, e a app lê o mesmo objecto.
///
/// **A versão é um campo do guia e não um pedaço do endereço**, e é a decisão
/// que custaria mais se fosse errada: as 24 páginas de guia foram indexadas
/// na semana de 02/11/2026, e é disso que depende o pedido de revisão do
/// AdSense. Passar `/guias/runas` a `/1.8.7/guias/runas` moveria 24 endereços
/// recém-indexados no mês em que o Google está a decidir se o site tem valor
/// — e o GitHub Pages não faz redirecionamento de servidor.
library;

/// Um guia: o que é, onde vive, e a que versões do jogo serve.
class Guia {
  const Guia({
    required this.titulo,
    required this.linha,
    required this.endereco,
    required this.publicado,
    this.versoes = const {},
    this.medida,
    this.noApp = false,
  });

  final String titulo;

  /// Uma linha a dizer o que o guia responde — não do que é feito.
  final String linha;

  /// O endereço, tal como vai para um `href` ou para o `Navigator`. Nenhum
  /// deles muda: ver a nota da biblioteca.
  final String endereco;

  /// Quando foi publicado. **Um facto, e dele sai o selo** — ver [novoEm].
  /// Guardar «é novo» como bandeira é o que faz um *novo* sobreviver meses
  /// ao que descrevia; guardar a data faz o selo apagar-se sozinho.
  final DateTime publicado;

  /// A que versões serve, pelo nome que o visitante lê — `1.8.7`, `1.2.6`,
  /// `1.4.4`. **Vazio quer dizer todas.**
  ///
  /// Medido a 09/11/2026: os guias de hoje são quase todos de 1.8.7 **sem o
  /// dizerem**. Runas, conduíte, astrolábio e cartas Nuema são conteúdo de
  /// 1.8.7; a Saga tem dezassete classes e o 1.2.6 tem seis. Só as multi
  /// contas servem as três, por falarem do cliente do jogo e não de um
  /// mercado.
  final Set<String> versoes;

  /// O que substitui o tempo de leitura quando ele mentiria.
  ///
  /// A Saga são dezoito páginas: somadas davam **«81 min de leitura»**, que
  /// ninguém lê de uma vez e que se lê como avaria. *17 classes, uma página
  /// cada* é a medida certa para um conjunto — um conjunto não tem duração,
  /// tem tamanho.
  final String? medida;

  /// Se vive dentro da app em vez de ser uma página HTML. Decide quem o
  /// abre — `Navigator` ou o browser — e se há ficheiro em disco para medir.
  final bool noApp;

  /// Um mês a contar da publicação.
  ///
  /// **A conta vive aqui e não em cada entrada**, para que nenhum guia possa
  /// ter um prazo próprio por distracção — e para que *um mês* queira dizer
  /// o mesmo em todos.
  static const duracaoDoSelo = Duration(days: 30);

  bool novoEm(DateTime agora) => agora.isBefore(publicado.add(duracaoDoSelo));

  /// Se serve a versão [versao]. `null` — a tela de escolha, que ainda não
  /// escolheu mercado — vê tudo, e é também o que a página `/guias/` faz
  /// quando ninguém filtrou: *todos os guias* é simplesmente não filtrar.
  bool serve(String? versao) =>
      versao == null || versoes.isEmpty || versoes.contains(versao);

  /// O ficheiro em disco, derivado do endereço — **nunca um campo a mais**.
  /// Um nome de ficheiro guardado ao lado do endereço que já o contém é o
  /// mesmo facto escrito duas vezes, e foi assim que o Ceifador ficou com a
  /// arte do Guerreiro nas Sagas.
  ///
  /// `null` para quem vive na app: não há página para medir.
  String? get arquivo {
    if (noApp) return null;
    final sem = endereco.startsWith('/') ? endereco.substring(1) : endereco;
    return sem.endsWith('/') ? 'web/${sem}index.html' : 'web/$sem.html';
  }
}

/// Os oito guias, na ordem em que a página os mostra.
///
/// A ordem é deliberada e não a de publicação: a Saga vem primeiro por ser a
/// maior e a mais pedida, e o *Início rápido* a seguir por ser o único que
/// serve quem acabou de instalar o jogo.
final guias = <Guia>[
  Guia(
    titulo: 'Saga do Herói: as 17 classes',
    linha:
        'O mascote e o título de +100 de HP de cada classe, lado a lado — e '
        'uma página por saga com todas as missões e as coordenadas.',
    endereco: '/guias/saga-do-heroi/',
    publicado: DateTime.utc(2026, 10, 29),
    versoes: const {'1.8.7'},
    medida: '17 classes, uma página cada',
  ),
  Guia(
    titulo: 'Início rápido',
    linha:
        'Como ganhar nível: as quests vermelhas, o Vale da Fênix e as '
        'Anedotas.',
    endereco: '/guias/inicio-rapido',
    publicado: DateTime.utc(2026, 8, 16),
    versoes: const {'1.8.7'},
  ),
  Guia(
    titulo: 'Quanto custa uma runa nível 10',
    linha:
        'São 648.000 runas nível 1, ou 125 runas nível 7 na consignação. E '
        'dois degraus da escada custam o dobro dos vizinhos — a janela de '
        'fusão não diz nenhuma das duas coisas.',
    endereco: '/guias/runas',
    publicado: DateTime.utc(2026, 10, 22),
    versoes: const {'1.8.7'},
  ),
  Guia(
    titulo: 'Cartas Nuema',
    linha:
        'As seis cartas S do conjunto Portal de Nuema, o que elas dobram, e '
        'as três maneiras de consegui-las.',
    endereco: '/guias/cartas-nuema',
    publicado: DateTime.utc(2026, 10, 23),
    versoes: const {'1.8.7'},
  ),
  Guia(
    titulo: 'O astrolábio, do primeiro ao nível máximo',
    linha:
        'As três barras, os quatro botões, a parede do nível 50 — e onde não '
        'desperdiçar pérola nem poeira.',
    endereco: '/guias/astrolabio',
    publicado: DateTime.utc(2026, 10, 28),
    versoes: const {'1.8.7'},
  ),
  // **O sexto, e por isso no último lugar que a secção mostra.** Ela corta em
  // seis e ele era o oitavo, portanto caía sempre fora — e é o único guia que
  // serve as três versões, logo o único que traz a etiqueta *todas as
  // versões*. Sem ele à vista, a secção perdia o que tinha para dizer sobre o
  // escopo de cada guia, e o 1.2.6 ficava com uma carta na home e nenhuma na
  // lista curta.
  //
  // Decisão do dono a 10/11/2026 — *«acho que vale a pena colocar o multi
  // contas em todos»*. O preço é o conduíte passar a ser o primeiro de fora;
  // com um tecto de seis, pôr um à vista tira outro.
  Guia(
    titulo: 'Multi contas',
    linha:
        'Jogar com mais de um cliente aberto: para que serve um segundo '
        'personagem e o que é preciso para o aguentar.',
    endereco: '/multicontas',
    publicado: DateTime.utc(2026, 10, 5),
    noApp: true,
  ),
  Guia(
    titulo: 'O conduíte, do começo ao nível máximo',
    linha:
        'Como subir, o que escolher em cada nível, e por que os níveis 50 e '
        '100 valem mais que todos os outros juntos.',
    endereco: '/guias/conduite',
    publicado: DateTime.utc(2026, 10, 27),
    versoes: const {'1.8.7'},
  ),
  Guia(
    titulo: 'Quests diárias',
    linha:
        'As mais fáceis e com melhor retorno, para fechar o dia em menos de '
        'uma hora — incluindo a que só funciona num personagem por IP.',
    endereco: '/guias/quests-diarias',
    publicado: DateTime.utc(2026, 10, 27),
    versoes: const {'1.8.7'},
  ),
  // **Serve as três, e é o único.** Fala do cliente do jogo e não de um
  // mercado — a mesma razão pela qual `/novidades` não tem prefixo de versão.
];

/// Os guias que servem [versao], na ordem da lista. `null` devolve todos.
List<Guia> guiasDe(String? versao) =>
    guias.where((g) => g.serve(versao)).toList();
