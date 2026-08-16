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

/// The menu.
///
/// **Only the first entry is real.** The other three are placeholders the
/// player has not confirmed — they exist so the grid can be judged at its
/// intended size rather than as a single card, and so the second tool costs a
/// line instead of a redesign. Replace the names and taglines; delete any that
/// are not wanted.
const tools = <Tool>[
  Tool(
    name: 'Market Filter',
    tagline:
        'Ache personagens à venda pelo equipamento, pelas cartas e pelos '
        'atributos.',
    icon: Icons.travel_explore,
    route: '/filtro',
    art: 'assets/images/barbaro.webp',
  ),
  Tool(
    name: 'Histórico de preços',
    tagline: 'Quanto um personagem já pediu, e há quanto tempo está à venda.',
    icon: Icons.show_chart,
    art: 'assets/images/espiritualista.webp',
  ),
  Tool(
    name: 'Comparador',
    tagline: 'Dois personagens lado a lado, peça por peça.',
    icon: Icons.balance,
    art: 'assets/images/sacerdote.webp',
  ),
  Tool(
    name: 'Calculadora de refino',
    tagline: 'Quanto custa levar uma arma do +10 ao +12.',
    icon: Icons.calculate_outlined,
  ),
];
