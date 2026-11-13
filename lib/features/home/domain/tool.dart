import 'package:flutter/material.dart';

import '../../guias/domain/guia.dart';

/// One entry on the Portal's front page.
///
/// Tools that do not exist yet belong here too, with `route: null`. A menu that
/// shows only what is finished makes the site look like it stopped growing, and
/// it makes every new tool a redesign. Listed and dimmed, the shape of the
/// place is visible from day one and shipping a tool is a one-line change.
///
/// **[icon], [emblem], [art] and [artAlignment] are read nowhere today.**
/// They were `ToolCard`'s — the front page's own tool cards, retired
/// 01/10/2026 when `Cabecalho`'s pills made them a duplicate menu. `GavetaItem`,
/// the one drawer row left, shows only [name], [tagline] and the two badges.
/// They stay on the class because a card is the natural place for this kind
/// of art and the idea is parked, not refuted — removing them would cost the
/// next card a redesign to get them back.
class Tool {
  const Tool({
    required this.name,
    required this.tagline,
    required this.icon,
    this.secao = 'Ferramentas',
    this.versoes = const {},
    this.emblem,
    this.novoAte,
    this.beta = false,
    this.route,
    this.href,
    this.art,
    this.artAlignment = const Alignment(0, -0.6),
  });

  final String name;

  /// One line, in the user's words rather than the product's — what question
  /// the tool answers, not what it is built from.
  final String tagline;

  final IconData icon;

  /// Which heading it sits under on the front page.
  ///
  /// The guides are not tools, and filing them together made the menu say
  /// "here are four things" where it should say "here is what the site does,
  /// and here is what it explains".
  final String secao;

  /// Which marketplaces this entry belongs to, by the version's display
  /// name — `1.8.7`, `1.2.6`. **Vazio quer dizer todas**, que é o caso de
  /// qualquer coisa que não dependa de um mercado.
  ///
  /// Existe porque a barra é a mesma em todas as telas e, até 05/10/2026,
  /// listava as ferramentas do 1.8.7 dentro do 1.2.6 — um menu a oferecer
  /// quatro portas das quais nenhuma servia a versão onde o visitante estava.
  /// Nenhuma delas erraria em silêncio: o filtro tem `/1.8.7/filtro` cravado
  /// na rota e teria trocado a versão debaixo dos pés de quem clicasse.
  final Set<String> versoes;

  /// Se esta entrada pertence à versão [versao]. `null` — o seletor, que
  /// ainda não escolheu mercado — vê tudo: ali a barra é o catálogo do site,
  /// e escondê-la toda deixaria a página de entrada sem menu.
  bool serveA(String? versao) =>
      versao == null || versoes.isEmpty || versoes.contains(versao);

  /// Until when the card wears a *novo* badge, or `null` for no badge.
  ///
  /// A date and not a flag, and that is the whole point: a badge nobody has
  /// to remember to remove is a badge that stops being true. This one expires
  /// on its own, which is the only kind of "new" a site can promise.
  final DateTime? novoAte;

  bool novoEm(DateTime agora) => novoAte != null && agora.isBefore(novoAte!);

  /// Still being checked against the game.
  ///
  /// **Unlike [novoAte] this has no expiry, and that is deliberate.** *Novo*
  /// stops being true by itself, so a date takes it down; *beta* stops being
  /// true only when somebody has actually verified the thing, which is an
  /// event and not a date. It comes off by hand, on the day the numbers have
  /// been checked against a real window.
  final bool beta;

  /// Item id whose art stands for the tool, drawn in place of [icon].
  ///
  /// The game's own picture beats a Material glyph for the same reason the
  /// filter's section headers use one: a card is scanned before it is read,
  /// and `Icons.travel_explore` says "search" where a gold coin says *this is
  /// about what things cost*. [icon] stays required as the fallback — an art
  /// file that was never fetched must leave a card whole, not empty.
  final int? emblem;

  /// A screen inside the app. `null` while the tool is still an idea, or when
  /// it lives at [href] instead.
  final String? route;

  /// A page outside the app, on the same domain.
  ///
  /// The guides are plain HTML and not Flutter screens because the app paints
  /// into a canvas: its pages carry no text in the DOM at all, which makes
  /// them unreadable to search engines and hostile to ads. Editorial content
  /// is exactly what should be findable, so it is served as ordinary pages and
  /// linked to from here.
  final String? href;

  /// Art behind the card, heavily darkened so the text stays readable.
  /// `null` falls back to the flat surface colour — a card without art must
  /// look deliberate, not broken.
  final String? art;

  /// Which part of [art] survives the crop.
  ///
  /// The default puts the crop's centre a fifth of the way down, because the
  /// three class portraits carry their faces there and `Alignment.center`
  /// landed the visible band on a priest's skirt — on the full-width card,
  /// which is where a bad crop shows first. A landscape has no face and wants
  /// its middle, so it says so.
  final Alignment artAlignment;

  bool get isReady => route != null || href != null;
}

/// Everything the front page lists, in the order it lists them.
///
/// A tool that does not exist yet belongs here too, dimmed: the page shows the
/// shape of the place from the start, and shipping one is a route away rather
/// than a redesign.
///
/// `final` and not `const` because of [Tool.novoAte] — a `DateTime` is not a
/// compile-time constant, which is the price of a badge that expires by
/// itself.
final tools = <Tool>[
  Tool(
    name: 'Filtro do Marketplace',
    // Says what you gain, never what the official marketplace lacks. The
    // people who run that site are the audience here, not the competition.
    tagline: 'Busque seu próximo personagem por arma, cartas e atributos.',
    icon: Icons.travel_explore,
    // Moeda de Ouro. The filter is about price as much as about gear.
    emblem: 39873,
    // The canonical path, not the bare `/filtro` the redirect in
    // `core/rotas.dart` keeps alive for old links. This menu writes a fresh
    // link every time somebody opens it from here, and a fresh link has to
    // carry the version from the start — see `AddressBar`'s own note on the
    // same asymmetry.
    route: '/1.8.7/filtro',
    versoes: const {'1.8.7'},
  ),
  Tool(
    name: 'Títulos',
    // Um mês de badge. A data vence sozinha, então ninguém precisa lembrar
    // de tirar — e "novo" para de ser verdade muito antes de alguém reparar.
    // O nome que a comunidade usa. "Registros de Assimilação" é como o item
    // se chama; o que o jogador quer são os títulos que ele destrava, e o
    // card tem que dizer a coisa pelo nome que ele procura.
    tagline:
        'O que cada registro dá de atributo e quanto custa em páginas — o '
        'NPC mostra 32 ícones iguais e não soma nada.',
    icon: Icons.workspace_premium_outlined,
    // A própria Página de Registro: Assimilação, que é a moeda da mecânica.
    emblem: 83070,
    route: '/registros',
    versoes: const {'1.8.7'},
    // Sem arte de personagem, de propósito. Era um sacerdote emprestado, que
    // não tem relação nenhuma com títulos — enchia o card e não dizia nada.
    // O emblema é a própria Página de Registro, ampliada e esmaecida atrás:
    // o assunto da ferramenta em vez de um retrato qualquer.
  ),
  Tool(
    name: 'Organizador de instâncias',
    // Diz o que se ganha, não o que a ferramenta é por dentro. Quem tem seis
    // personagens não procura "um organizador": procura saber em qual é que
    // ainda há chave.
    tagline:
        'Quantas Relíquias Maravilha e Chaves da Sorte cada personagem seu '
        'tem — e em qual delas ainda sobra entrada.',
    icon: Icons.checklist_rtl_outlined,
    // A Chave da Sorte, que é o que acaba primeiro e o que se vem cá ver.
    emblem: 56274,
    route: '/instancias',
    versoes: const {'1.8.7'},
    novoAte: _ateDezembro,
  ),
  Tool(
    name: 'Calculadora de runas',
    // O número é a manchete. A janela de fusão mostra uma porcentagem e nada
    // mais: nunca diz que a runa no centro é a vigésima quinta que alguém vai
    // alimentar, nem que dois dos nove degraus custam seis runas onde os
    // vizinhos custam quatro.
    tagline:
        'Quanto custa cada runa, de verdade: uma nível 10 são 648.000 runas '
        'nível 1. Diz o que falta a partir do que você já tem.',
    icon: Icons.calculate_outlined,
    // Uma runa Argêntea nível 10 — a arte mais elaborada das cinquenta, e o
    // próprio assunto da ferramenta.
    emblem: 52224,
    route: '/runas',
    versoes: const {'1.8.7'},
    // Sem arte de personagem: as quatro do repositório já estão em uso e
    // repetir uma faria dois cards disputarem a mesma imagem. O emblema é uma
    // runa de verdade, que diz mais sobre a ferramenta que um retrato diria.
  ),
  // The guides are listed one by one rather than behind a single "read the
  // guides" card. There is one written, so this is one card — and that is the
  // point: a card that leads to a list of one is a click spent on nothing, and
  // as guides are written the front page fills itself.
  // **Guerras territoriais saiu da lista em 29/09/2026, e não virou um card
  // apagado — saiu inteiro.** Um *em breve* é uma promessa com data implícita,
  // e uma promessa que fica meses na primeira dobra ensina o visitante a não
  // acreditar na próxima. A regra que justifica listar o que não existe ainda
  // supõe que a coisa está a caminho; esta não está.
  //
  // A página continua publicada em `/guerras/` e continua sem link daqui — o
  // que muda é que a home parou de anunciá-la. Para trazê-la de volta são
  // três gestos que andam juntos, e fazer um só deixa o site incoerente
  // consigo mesmo: devolver o `Tool` aqui **com `href`**, tirar o `noindex`
  // das duas páginas e devolvê-las ao sitemap.
  //
  // `assets/images/barbaro.webp` ficou livre com a saída dela.
  // **Esta entrada era o *Início rápido* e passou a ser a Saga do Herói a
  // 29/10/2026, a pedido do dono, e a troca é sobre a quem a gaveta serve.**
  // A gaveta tem duas entradas de Guias: uma destacada e a porta para a
  // lista inteira. A destacada estava gasta com o guia que serve quem está
  // a começar — e quem está a começar não abre menus, abre o jogo. Quem abre
  // esta gaveta já joga, e para esse a pergunta corrente é qual saga fazer.
  //
  // O *Início rápido* não saiu do site: continua em `web/guias/index.html`,
  // que é a lista que se mantém sozinha, e a entrada *Todos os guias* logo
  // abaixo leva lá. É exactamente a divisão que essa entrada existe para
  // garantir — o menu destaca um, a lista guarda todos.
  // **A porta para a lista, e ela existe porque havia duas listas de guias que
  // não sabiam uma da outra.** Os artigos vivem em `web/guias/index.html`, que
  // se mantém sozinho; o menu vive aqui. O guia das runas foi publicado a
  // 22/10/2026, entrou no índice HTML, não entrou nesta lista — e ficou **sem
  // nenhum caminho a partir do site**, porque nada ligava para `/guias/`
  // tampouco. Estava no sitemap, portanto o Google chegava lá e um visitante
  // não.
  //
  // A correcção deliberadamente **não** é dar um `Tool` a cada artigo: isso
  // repara o terceiro e deixa o quarto cair no mesmo buraco. É uma entrada
  // para a lista que já se mantém, e a partir daqui um guia novo aparece no
  // menu sem ninguém se lembrar de nada.
  // **E esta é a volta da entrada que saiu em 29/09/2026**, agora com algo
  // atrás dela. Saiu porque era um *em breve* sem data, e um *em breve* que
  // fica meses na primeira dobra ensina o visitante a não acreditar no
  // próximo. Volta com `route` e não com `href` porque agora é uma tela do
  // site e não uma página estática em `web/guerras/`.
  Tool(
    name: 'Vídeos de Guerras Territoriais',
    tagline:
        'Vídeos de guerra gravados pela comunidade, por classe — e todos '
        'com permissão de quem gravou.',
    icon: Icons.videocam_outlined,
    // **Secção própria, não os Guias** — decisão do dono em 05/10/2026, e tem
    // razão: um vídeo de guerra não explica nada, mostra. Com uma entrada só,
    // a pílula leva direto à tela em vez de abrir uma gaveta de um item.
    // **A pílula diz `Guerras` e a entrada diz o nome inteiro**, e isso é
    // medido e não preferência: já com `Guerras Territoriais` a barra
    // transbordava 70 px ao lado de *Ferramentas*, *Guias* e *Novidades*,
    // com as fontes reais, e o nome ficou ainda mais longo a 10/11/2026.
    // Uma pílula é um rótulo, não um título — o nome completo está no
    // cabeçalho da tela e na dica da própria pílula.
    secao: 'Guerras',
    // `{versao}` é substituído pela versão em que o visitante está — as
    // guerras existem nos dois mercados, e duas entradas com o mesmo nome
    // divergiriam na primeira vez que alguém editasse só uma.
    route: '/{versao}/guerras',
    versoes: const {'1.8.7', '1.2.6'},
  ),
];

/// Um mês a contar da publicação do organizador de instâncias, a 11/11/2026.
///
/// É o único selo de *novo* em uso: o redesenho de Novembro recalcula o dos
/// guias a partir de `guia.publicado` (ver abaixo), e os selos antigos já
/// tinham saído ou expirado sozinhos.
final _ateDezembro = DateTime.utc(2026, 12, 11);

/// As seções na ordem em que a home as mostra, cada uma uma vez.
///
/// Lida da lista e não escrita à parte: uma segunda lista das seções seria
/// uma segunda coisa para manter em acordo, e a que fica para trás é sempre a
/// que ninguém olha.
List<String> get secoesDaHome {
  final vistas = <String>{};
  return [
    for (final tool in tools)
      if (vistas.add(tool.secao)) tool.secao,
    // **Os guias não estão em `tools` e por isso entram à mão.** A gaveta
    // deles é a lista de `guias`, derivada, e não três entradas escritas
    // aqui — ver `_guiasComoTools`. Sem esta linha a secção desaparecia da
    // barra no dia em que as entradas à mão saíram, que foi exactamente o
    // que a suíte apanhou.
    if (vistas.add(seccaoDosGuias)) seccaoDosGuias,
  ];
}

/// Os cards de uma seção, na ordem da lista, para a versão em que se está.
List<Tool> toolsDe(String secao, {String? versao}) => secao == seccaoDosGuias
    ? _guiasComoTools(versao)
    : [
        for (final tool in tools)
          if (tool.secao == secao && tool.serveA(versao)) tool,
      ];

/// O nome da secção dos guias, escrito uma vez.
const seccaoDosGuias = 'Guias';

/// A gaveta dos *Guias* é a lista dos guias, e não uma selecção à mão.
///
/// **Era curada — a Saga, *Todos os guias* e as multi contas — e a pílula
/// dizia três.** A maquete diz **oito**, e o dono escolheu o número dela:
/// quem chega quer saber quantos artigos há, não quantas entradas alguém
/// destacou. Com a conta a vir da lista, as duas passam a dizer o mesmo
/// número pela única razão que resiste: são a mesma coisa.
///
/// **A entrada *Todos os guias* saiu da gaveta e não saiu do site.** Ela
/// existia para haver um caminho até `/guias/`, e esse caminho está agora na
/// própria página, na régua da secção — `os 8 →`. Duas portas para a mesma
/// lista na mesma tela era o que o dono já tinha recusado nas ferramentas.
///
/// **E a Saga deixou de ser destaque, que é a metade que se perde.** Ela era
/// a primeira da gaveta por ser a maior; passa a ser a primeira da lista, que
/// é onde a ordem de `guias` já a põe.
List<Tool> _guiasComoTools(String? versao) => [
  for (final guia in guiasDe(versao))
    Tool(
      name: guia.titulo,
      tagline: guia.linha,
      icon: Icons.menu_book_outlined,
      secao: seccaoDosGuias,
      versoes: guia.versoes,
      // Um mês a contar da publicação, derivado e não escrito — ver
      // `Guia.publicado`. Um *novo* que ninguém se lembra de tirar deixa de
      // ser verdade muito antes de alguém reparar.
      novoAte: guia.publicado.add(Guia.duracaoDoSelo),
      route: guia.noApp ? guia.endereco : null,
      href: guia.noApp ? null : guia.endereco,
    ),
];

/// Se abrir [tool] escolheria um mercado por quem clicou.
///
/// **A pergunta é sobre o destino e não sobre [Tool.versoes]**, e a primeira
/// versão disto olhou para o campo errado. *Todos os guias* declara-se de
/// 1.8.7 e é literalmente a lista das três versões; abri-lo leva a uma página
/// HTML que não pertence a mercado nenhum. `versoes` diz em que menus a
/// entrada aparece — outra pergunta.
///
/// O que escolhe mercado é uma rota que **nomeia uma versão**: a marca
/// `{versao}`, que `rotaDaTool` preenche com o 1.8.7 quando não há nenhuma, ou
/// um prefixo cravado como `/1.8.7/filtro`. Um `href` nunca escolhe: é uma
/// página do site, servida igual a toda a gente.
bool escolheMercado(Tool tool) {
  final rota = tool.route;
  if (rota == null) return false;
  if (rota.contains('{versao}')) return true;
  return _prefixosDeVersao.any((p) => rota.startsWith('/$p/'));
}

/// Os prefixos que `core/rotas.dart` conhece. Escritos aqui e não importados
/// porque `domain/` não depende de `core/rotas.dart` — e o 1.4.4 entra na
/// lista no dia em que ganhar rota, que é o mesmo dia em que ganha prefixo.
const _prefixosDeVersao = ['1.8.7', '1.2.6', '1.4.4'];

/// Se [secao] pode ser oferecida numa tela que ainda não escolheu mercado.
///
/// **A regra é derivada e não declarada**, e isso é o ponto. `Cabecalho`
/// escondia as duas secções na raiz com uma bandeira — `semMercado` — posta à
/// mão a 27/10/2026, porque `rotaDaTool` sem versão cai no 1.8.7 e clicar ali
/// escolhia o mercado em silêncio. A bandeira resolvia o defeito e não sabia
/// porque existia: no dia em que uma secção deixasse de ter entradas presas a
/// um mercado, continuaria escondida.
///
/// Foi o que aconteceu. Os *Guias* são três entradas que nenhuma escolhe
/// mercado — duas são endereços de páginas HTML e a terceira, as multi
/// contas, perdeu o prefixo a 09/11/2026. *Ferramentas* tem o filtro cravado
/// em `/1.8.7/filtro` e continua escondida, que é o defeito original a
/// continuar tapado pela razão certa.
bool secaoServeSemMercado(String secao) =>
    toolsDe(secao).every((t) => !escolheMercado(t));
