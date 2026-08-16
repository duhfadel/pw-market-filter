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
    this.featured = false,
  });

  final String name;

  /// One line, in the user's words rather than the product's — what question
  /// the tool answers, not what it is built from.
  final String tagline;

  final IconData icon;

  /// `null` while the tool is still an idea.
  final String? route;

  /// Gets the wide card. With every entry the same size the eye has nowhere to
  /// land, and the one tool that actually works should be the obvious one.
  final bool featured;

  bool get isReady => route != null;
}

/// The menu.
///
/// Only the Market Filter exists. The rest of the list is waiting on the
/// player — names and one line each — and until then the page carries a single
/// featured card, which is the layout it was built to survive.
const tools = <Tool>[
  Tool(
    name: 'Market Filter',
    tagline:
        'Ache personagens à venda pelo equipamento, pelas cartas e pelos '
        'atributos — o que o marketplace não deixa filtrar.',
    icon: Icons.travel_explore,
    route: '/filtro',
    featured: true,
  ),
];
