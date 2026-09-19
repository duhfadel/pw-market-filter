import 'package:flutter/material.dart';

/// The Discord mark, tinted like any other icon.
///
/// Flutter ships no Discord glyph and the project takes no new dependency for
/// one, so the official mark is an asset — rendered from Discord's own SVG at
/// 192 px, white on transparent, which makes it a **mask**: the colour comes
/// from [color] through `srcIn`, so the same file is orange on the page and
/// dark inside a filled button. A coloured PNG would need one file per place
/// it appears.
///
/// It falls back to a generic chat glyph rather than to a gap, for the same
/// reason [ItemIcon] falls back to an empty box: a missing file must not turn
/// a link into something nobody can recognise.
class DiscordIcon extends StatelessWidget {
  const DiscordIcon({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/discord.png',
    width: size,
    height: size,
    color: color,
    // Paints `color` wherever the mask is opaque and keeps the transparency.
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, _, _) =>
        Icon(Icons.forum_outlined, size: size, color: color),
  );
}
