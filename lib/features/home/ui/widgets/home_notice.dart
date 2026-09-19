import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/brand_icon.dart';
import '../../domain/community.dart';

/// The body of the first news entry: the word from whoever made the site.
///
/// It was a standing panel with its own title and frame until the news section
/// took both — what is left here is the message, which is the part that will
/// still read correctly when it is the third item down instead of the first.
///
/// **What it claims about The Classic is worded to the letter of what they
/// answered** — *não iremos impedir ou bloquear as criações realizadas* — and
/// nothing beyond it. They refused a partnership and take no responsibility
/// for the site; rounding "we will not block you" up to "authorised by The
/// Classic" is the one sentence here that could cost the project, and the
/// `CLAUDE.md` says so in the same words.
///
/// The four asks are a list and not prose. They are four different actions —
/// join, tip, suggest, partner — and a reader scanning for the one that
/// applies to them should not have to read the other three to find it.
class HomeNotice extends StatelessWidget {
  const HomeNotice({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'O The Classic não quis parceria, mas confirmou que não vai impedir '
        'nem bloquear o site. Então, atendendo aos pedidos da comunidade, o '
        'filtro do marketplace continua no ar — e em breve teremos mais '
        'ferramentas para ajudar os jogadores.',
        style: TextStyle(color: PWColors.text, fontSize: 14, height: 1.65),
      ),
      SizedBox(height: wide ? 18 : 15),
      const _Ask(
        // The mark and not a generic speech bubble: this line names Discord,
        // and the button four lines down carries the real logo — two
        // drawings for one thing reads as two different things.
        icone: DiscordIcon(size: 16, color: PWColors.accent),
        titulo: 'Gosta do site?',
        texto: 'Segue o nosso canal no Discord.',
      ),
      const _Ask(
        icone: Icon(
          Icons.local_cafe_outlined,
          size: 17,
          color: PWColors.accent,
        ),
        titulo: 'Gostou muito?',
        texto:
            'Paga um cafezinho: manda um gold para o meu personagem no '
            'The Classic 1.8.7, nick ',
        // The one word on this line somebody has to copy into the game, so
        // it carries the weight the rest of the sentence does not.
        destaque: 'duhit',
      ),
      const _Ask(
        icone: Icon(Icons.lightbulb_outline, size: 17, color: PWColors.accent),
        titulo: 'Tem uma ideia nova?',
        texto: 'Manda pra mim no Discord!',
      ),
      const _Ask(
        icone: Icon(Icons.handshake_outlined, size: 17, color: PWColors.accent),
        titulo: 'Quer parceria?',
        texto: 'Banner, montar o seu site, o que for — fala comigo no Discord.',
      ),
      SizedBox(height: wide ? 6 : 4),
      // One button for all four asks, because three of them end at the same
      // door. Repeating it per line would make the panel look like an advert
      // for the server rather than a note from a person.
      FilledButton.icon(
        onPressed: () => unawaited(
          launchUrl(
            Uri.parse(discordInvite),
            mode: LaunchMode.externalApplication,
          ),
        ),
        icon: const DiscordIcon(size: 17, color: PWColors.background),
        label: const Text('Entrar no Discord do Portal PW'),
      ),
      SizedBox(height: wide ? 16 : 14),
      const Text(
        'Obrigado a todos!',
        style: TextStyle(color: PWColors.text, fontSize: 14, height: 1.65),
      ),
      const Text(
        '— duhit',
        style: TextStyle(color: PWColors.textMuted, fontSize: 13),
      ),
    ],
  );
}

/// One line of the list: what you might want, and what to do about it.
class _Ask extends StatelessWidget {
  const _Ask({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.destaque,
  });

  /// A widget and not an `IconData`, because one of the four is a brand mask
  /// rather than a font glyph.
  final Widget icone;
  final String titulo;
  final String texto;

  /// Closes the line in bold, for a value the reader has to take away — a
  /// nickname to type into the game is not prose.
  final String? destaque;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nudged down to sit on the first line's baseline rather than on the
        // top of its box, which reads as floating above the text.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(width: 18, child: Center(child: icone)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$titulo ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: texto),
                if (destaque != null)
                  TextSpan(
                    text: destaque,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PWColors.accent,
                    ),
                  ),
                if (destaque != null) const TextSpan(text: '.'),
              ],
            ),
            style: const TextStyle(
              color: PWColors.text,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),
      ],
    ),
  );
}
