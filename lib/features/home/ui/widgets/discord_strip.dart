import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/brand_icon.dart';
import '../../domain/community.dart';

/// The invitation, under the front page's own `COMUNIDADE` heading.
///
/// It is the one thing on this page that outlives any single visit: whoever
/// joins the server hears about the next tool without having to remember the
/// address. Everything else on this page answers "what does it do"; this
/// answers "how do I stay".
///
/// **It used to sit above the logo, and moved when the page did.** The
/// `Cabecalho` now carries the mark, and this line moved down to sit under
/// its own honest heading instead — it used to double as the ad slot's house
/// ad, wearing a `PUBLICIDADE` label that trained readers to skip exactly the
/// thing it was meant to present. It is not advertising, it is the owner's
/// own channel.
///
/// **A strip and not a banner.** It is one line, on the page's own background,
/// with no card around it — anything heavier competes with the section
/// above it for the same attention.
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
                    // on a narrow screen: the invitation survives, the reason
                    // does not.
                    //
                    // It said *"e converse com quem joga também"* until
                    // 02/10/2026, and the owner killed it with the only
                    // argument that matters: **nobody joins a Discord to talk
                    // to strangers.** An invitation has to offer something the
                    // reader already wants, and what somebody on this page
                    // wants is a tool that works and a tool that exists.
                    //
                    // So it names the two things this server is actually for,
                    // and both are errands the reader may already have: a
                    // defect to report, and a tool to ask for. Neither is a
                    // promise about other people.
                    //
                    // Not "novidades" — the page has its own `NOVIDADES DO
                    // PORTAL` section a few rows up, and the same word here
                    // would read as the same thing.
                    if (wide)
                      const TextSpan(
                        text: '  achou um bug? quer pedir uma ferramenta?',
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
