import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/brand_icon.dart';
import '../../domain/community.dart';
import '../../domain/visit_label.dart';
import '../visit_counter_view_model.dart';

/// The lines every page of this site ends with.
///
/// **Lifted out of the home on 2026-10-04 so the chooser could carry it too**,
/// at the owner's request — and the reason it matters is in the first
/// sentence it prints. The chooser is now the page a stranger lands on, so
/// the one screen that said nothing about what this site is was the one
/// everybody saw first.
///
/// It reads [VisitCounterViewModel] off the provider that `main.dart` mounts
/// above every route, so nothing has to be passed in and the count stays one
/// arrival per visitor rather than one per screen.
class Rodape extends StatelessWidget {
  const Rodape({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'Projeto de fã, sem vínculo com o The Classic Games. Lê apenas páginas '
        'públicas do marketplace.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 8),
      // **A licença cobre o repositório; esta linha cobre a página.** Quem
      // copia não clona o repositório — olha o site, e em 29/09/2026 onze dos
      // nossos quinze nomes de combo apareceram no bundle de outro site. Sem
      // nada escrito aqui, "não sabia" é uma defesa disponível.
      //
      // Duas frases e não uma, porque elas dizem coisas opostas e juntá-las
      // seria reivindicar o que não é nosso: o que reservamos são as
      // compilações — os combos, a escada das runas, as 126 receitas —, e
      // nomes, arte e dados do jogo são da The Classic. Reivindicar esses
      // seria falso e enfraqueceria o resto.
      const Text(
        '© 2026 Portal PW · todos os direitos reservados sobre o código e as '
        'compilações deste site.\nNomes, atributos e arte do jogo pertencem à '
        'The Classic Games.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PWColors.textMuted, fontSize: 11, height: 1.5),
      ),
      const _VisitCount(),
      // The mark alone, in the corner. The invitation is spelled out in its
      // own section higher up the page; a second one here would be nagging.
      // What a footer icon is for is the visitor who has already decided and
      // is looking for the door — and it carries a tooltip and a semantic
      // label, because a lone glyph with no words is exactly the thing a
      // screen reader cannot guess.
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () => unawaited(
            launchUrl(
              Uri.parse(discordInvite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          tooltip: 'Discord do Portal PW',
          icon: const DiscordIcon(size: 19, color: PWColors.textMuted),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(),
        ),
      ),
    ],
  );
}

/// Visits, once they are known.
///
/// It says *visitas* and not *pessoas* because that is what it counts: one per
/// browser per day. Claiming people would be a small lie that grows with the
/// number.
///
/// Nothing is drawn while the count is unknown — no spinner, no dash, no
/// "carregando". Whoever reads a footer is not waiting on it, and a counter
/// that fails should look like a page that never had one.
class _VisitCount extends StatelessWidget {
  const _VisitCount();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<VisitCounterViewModel, int?>(
        builder: (context, total) => total == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  visitLabel(total),
                  style: const TextStyle(
                    color: PWColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
      );
}
