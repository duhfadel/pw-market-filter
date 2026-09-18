import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/community.dart';

/// A word from whoever made the site, on the front page.
///
/// It exists because the site was closed for four days and came back, and the
/// visitor who returns deserves to be told why by a person rather than to find
/// the tool silently working again.
///
/// **It sits under the tools, not over them.** The first thing the page owes
/// anyone is what it does; a wall of text above the search button would bury
/// the one thing they came for. Whoever cares about the story scrolls, and it
/// is right there.
///
/// The claim about The Classic is worded to the letter of what they answered —
/// *não iremos impedir ou bloquear as criações realizadas* — and carries the
/// other half of it too, that they take no responsibility. Rounding a "we
/// won't block you" up to a blessing would be the one lie that could cost the
/// site everything.
class HomeNotice extends StatelessWidget {
  const HomeNotice({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(wide ? 26 : 20),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: const Border(
        left: BorderSide(color: PWColors.accent, width: 3),
        top: BorderSide(color: PWColors.border),
        right: BorderSide(color: PWColors.border),
        bottom: BorderSide(color: PWColors.border),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O Portal PW está de volta',
          style: TextStyle(
            color: PWColors.accent,
            fontSize: wide ? 20 : 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        SizedBox(height: wide ? 16 : 13),
        _p('Olá, pessoal!'),
        _p(
          'Levei o pedido de parceria à equipe do The Classic mais uma vez, e '
          'desta vez veio uma resposta clara: eles não vão impedir nem '
          'bloquear o site. Não se responsabilizam por ele — o que é justo, já '
          'que o projeto é meu — mas não há nada no caminho.',
        ),
        _p(
          'Então, pelos inúmeros agradecimentos que recebi de vocês nestes '
          'dias, estou reabrindo.',
        ),
        _p(
          'Para não restar dúvida: este site não é oficial e não somos '
          'parceiros da The Classic. É um projeto de fã, feito por mim, '
          'duhit, sem fins lucrativos.',
        ),
        _p(
          'Sigo atrás de parcerias, para movimentar a comunidade e conseguir '
          'melhorar o site. Criei um canal no Discord para juntar quem usa o '
          'Portal — entra lá:',
        ),
        // A button and not a line of prose: it is the one thing in this panel
        // a reader has to act on.
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 14),
          child: FilledButton.icon(
            onPressed: () => unawaited(
              launchUrl(
                Uri.parse(discordInvite),
                mode: LaunchMode.externalApplication,
              ),
            ),
            icon: const Icon(Icons.forum_outlined, size: 18),
            label: const Text('Entrar no Discord do Portal PW'),
          ),
        ),
        // The handle stays beside the invite because they are not the same
        // offer: the room is where the community reads each other, and this is
        // a private word with the person who built it. It is text and not a
        // link because Discord has no address that opens a DM to a username.
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SelectableText(
            'Ou me chama direto: $discordHandle',
            style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
          ),
        ),
        _p('Obrigado de verdade. Espero que seja útil.'),
        _p('Um abraço a todos.'),
        const Text(
          '— duhit',
          style: TextStyle(color: PWColors.textMuted, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _p(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      texto,
      style: const TextStyle(color: PWColors.text, fontSize: 14, height: 1.65),
    ),
  );
}
