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

/// The three sections of the Portal.
///
/// Only the first is built. The other two are listed and dimmed so the page
/// shows the shape of the place from the start — and so shipping one is a
/// route away, not a redesign.
const tools = <Tool>[
  Tool(
    name: 'Filtro do Marketplace',
    // Says what you gain, never what the official marketplace lacks. The
    // people who run that site are the audience here, not the competition.
    tagline: 'Busque seu próximo personagem por arma, cartas e atributos.',
    icon: Icons.travel_explore,
    route: '/filtro',
    art: 'assets/images/espiritualista.webp',
  ),
  Tool(
    name: 'Guerras territoriais',
    tagline:
        'Fique por dentro do que está acontecendo: entrevistas e as últimas '
        'notícias das guerras.',
    icon: Icons.local_fire_department_outlined,
    art: 'assets/images/barbaro.webp',
  ),
  // The guides are listed one by one rather than behind a single "read the
  // guides" card. There is one written, so this is one card — and that is the
  // point: a card that leads to a list of one is a click spent on nothing, and
  // as guides are written the front page fills itself.
  Tool(
    name: 'Início rápido',
    tagline:
        'Como ganhar nível: as quests vermelhas, o Vale da Fênix e as '
        'Anedotas.',
    icon: Icons.auto_stories_outlined,
    href: '/guias/inicio-rapido',
    art: 'assets/images/guia-inicio-rapido.webp',
    // A landscape, not a portrait: it wants its middle.
    artAlignment: Alignment.center,
  ),
];
