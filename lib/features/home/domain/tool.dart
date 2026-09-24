import 'package:flutter/material.dart';

/// One entry on the Portal's front page.
///
/// Tools that do not exist yet belong here too, with `route: null`. A menu that
/// shows only what is finished makes the site look like it stopped growing, and
/// it makes every new tool a redesign. Listed and dimmed, the shape of the
/// place is visible from day one and shipping a tool is a one-line change.
class Tool {
  const Tool({
    required this.name,
    required this.tagline,
    required this.icon,
    this.secao = 'Ferramentas',
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
    route: '/filtro',
    art: 'assets/images/espiritualista.webp',
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
    // Sem arte de personagem: as quatro do repositório já estão em uso e
    // repetir uma faria dois cards disputarem a mesma imagem. O emblema é uma
    // runa de verdade, que diz mais sobre a ferramenta que um retrato diria.
  ),
  // The guides are listed one by one rather than behind a single "read the
  // guides" card. There is one written, so this is one card — and that is the
  // point: a card that leads to a list of one is a click spent on nothing, and
  // as guides are written the front page fills itself.
  Tool(
    name: 'Guerras territoriais',
    tagline:
        'O mapa dos 52 territórios de Pangu: quem domina cada um e quanto '
        'de gold rende.',
    icon: Icons.local_fire_department_outlined,
    // A página existe e está publicada em /guerras/, mas o card continua sem
    // href de propósito: ela está sendo mostrada a um punhado de pessoas antes
    // de ser anunciada. Ligar aqui é o gesto que a torna pública — junto com
    // tirar o `noindex` das duas páginas e devolvê-las ao sitemap. Os três
    // andam juntos; fazer um só deixa o site incoerente consigo mesmo.
    art: 'assets/images/barbaro.webp',
  ),
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
    art: 'assets/images/guia-inicio-rapido.webp',
    // A landscape, not a portrait: it wants its middle.
    artAlignment: Alignment.center,
  ),
];

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

/// Os cards de uma seção, na ordem da lista.
List<Tool> toolsDe(String secao) => [
  for (final tool in tools)
    if (tool.secao == secao) tool,
];
