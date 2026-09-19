import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/brand_icon.dart';
import '../../domain/community.dart';

/// The invitation at the top of the front page.
///
/// It sits above the logo because it is the one thing here that outlives any
/// single visit: whoever joins the server hears about the next tool without
/// having to remember the address. Everything else on this page answers "what
/// does it do"; this answers "how do I stay".
///
/// **A strip and not a banner.** It is one line, on the page's own background,
/// with no card around it — anything heavier competes with the headline, which
/// is what a first-time visitor actually came to read.
class DiscordStrip extends StatelessWidget {
  const DiscordStrip({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) => Align(
    // Right on a desktop, where the eye finishes a line and the corner is free;
    // centred on a phone, where a corner is just the edge of a narrow column.
    alignment: wide ? Alignment.centerRight : Alignment.center,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => unawaited(
        launchUrl(
          Uri.parse(discordInvite),
          mode: LaunchMode.externalApplication,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DiscordIcon(size: 15, color: PWColors.accent),
            const SizedBox(width: 7),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Siga nosso Discord',
                      style: TextStyle(
                        color: PWColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // The reason to click, and the half that is dropped first
                    // on a narrow screen: the invitation survives, the sales
                    // pitch does not.
                    if (wide)
                      const TextSpan(
                        text: '  e fique por dentro das novidades!',
                      ),
                  ],
                ),
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
