import 'package:flutter/material.dart';

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
    novoAte: _ateOutubro,
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
    name: 'Calculadora de runas',
    beta: true,
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
  Tool(
    name: 'Início rápido',
    tagline:
        'Como ganhar nível: as quests vermelhas, o Vale da Fênix e as '
        'Anedotas.',
    icon: Icons.auto_stories_outlined,
    secao: 'Guias',
    // Pedra de Hiper EXP, which is what the guide is about: levelling fast.
    emblem: 27424,
    href: '/guias/inicio-rapido',
    versoes: const {'1.8.7'},
  ),
  // **E esta é a volta da entrada que saiu em 29/09/2026**, agora com algo
  // atrás dela. Saiu porque era um *em breve* sem data, e um *em breve* que
  // fica meses na primeira dobra ensina o visitante a não acreditar no
  // próximo. Volta com `route` e não com `href` porque agora é uma tela do
  // site e não uma página estática em `web/guerras/`.
  Tool(
    name: 'Multi contas',
    // Um mês de badge, e a data vence sozinha: um "novo" que ninguém se
    // lembra de tirar deixa de ser verdade muito antes de alguém reparar.
    novoAte: _ateNovembro,
    tagline:
        'Jogar com mais de um cliente aberto: para que serve um segundo '
        'personagem e o que é preciso para o aguentar.',
    icon: Icons.devices_other_outlined,
    secao: 'Guias',
    // A Pedra do Teletransporte: o item de quem anda com dois personagens
    // em dois sítios ao mesmo tempo.
    emblem: 23040,
    route: '/1.8.7/multicontas',
    versoes: const {'1.8.7'},
  ),
  Tool(
    name: 'Guerras Territoriais',
    tagline:
        'Vídeos de guerra gravados pela comunidade, por classe — e todos '
        'com permissão de quem gravou.',
    icon: Icons.videocam_outlined,
    // **Secção própria, não os Guias** — decisão do dono em 05/10/2026, e tem
    // razão: um vídeo de guerra não explica nada, mostra. Com uma entrada só,
    // a pílula leva direto à tela em vez de abrir uma gaveta de um item.
    // **A pílula diz `Guerras` e a tela diz `Guerras Territoriais`**, e isso
    // é medido e não preferência: com o nome inteiro a barra transbordava
    // 70 px ao lado de *Ferramentas*, *Guias* e *Novidades*, com as fontes
    // reais. Uma pílula é um rótulo, não um título — o nome completo está no
    // cabeçalho da tela e na dica da própria pílula.
    secao: 'Guerras',
    novoAte: _ateNovembro,
    // `{versao}` é substituído pela versão em que o visitante está — as
    // guerras existem nos dois mercados, e duas entradas com o mesmo nome
    // divergiriam na primeira vez que alguém editasse só uma.
    route: '/{versao}/guerras',
    versoes: const {'1.8.7', '1.2.6'},
  ),
];

/// Quando o selo de *novo* das Guerras vence.
final _ateNovembro = DateTime.utc(2026, 11, 5);

/// Quando o selo de *novo* dos Títulos vence.
final _ateOutubro = DateTime.utc(2026, 10, 20);

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
  ];
}

/// Os cards de uma seção, na ordem da lista, para a versão em que se está.
List<Tool> toolsDe(String secao, {String? versao}) => [
  for (final tool in tools)
    if (tool.secao == secao && tool.serveA(versao)) tool,
];
