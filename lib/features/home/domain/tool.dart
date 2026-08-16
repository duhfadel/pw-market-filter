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
    this.art,
  });

  final String name;

  /// One line, in the user's words rather than the product's — what question
  /// the tool answers, not what it is built from.
  final String tagline;

  final IconData icon;

  /// `null` while the tool is still an idea.
  final String? route;

  /// Class art behind the card, heavily darkened so the text stays readable.
  /// `null` falls back to the flat surface colour — a card without art must
  /// look deliberate, not broken.
  final String? art;

  bool get isReady => route != null;
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
  Tool(
    name: 'Começando no PW? Aprenda aqui',
    tagline: 'Ideias e sugestões de como iniciar no mundo de Pangu.',
    icon: Icons.auto_stories_outlined,
    art: 'assets/images/sacerdote.webp',
  ),
];
