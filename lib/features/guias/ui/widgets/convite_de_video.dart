import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../home/domain/community.dart';

/// O convite a quem grava: o Discord e o nick no jogo.
///
/// **A política é o conteúdo destas telas.** Nada é garimpado — um vídeo só
/// entra porque alguém se ofereceu — portanto o convite é a porta por onde a
/// página se enche, e fica visível mesmo com a grelha cheia. Escondê-lo
/// depois de entrar o primeiro vídeo fecharia essa porta.
///
/// **[chamada] muda e o resto não**, que é a razão de isto ser um widget e
/// não duas cópias. A tela inteira pergunta *«Quer o seu vídeo aqui?»* com a
/// grelha por trás; a secção da home de um mercado sem vídeo nenhum tem de
/// dizer primeiro que não tem — *«Ainda não temos vídeos de guerra do
/// 1.2.6»* — porque aí o convite está a explicar um vazio e não a somar a um
/// cheio. São perguntas diferentes; o Discord e o nick são os mesmos, e dois
/// sítios a escrevê-los à mão é como um deles fica para trás no dia em que o
/// convite mudar.
class ConviteDeVideo extends StatelessWidget {
  const ConviteDeVideo({required this.chamada, super.key});

  /// A primeira linha: o que esta tela está a pedir, nas palavras dela.
  final String chamada;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PWColors.border),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          chamada,
          style: const TextStyle(
            color: PWColors.papel,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        InkWell(
          onTap: () => unawaited(
            launchUrl(
              Uri.parse(discordInvite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          child: const Text(
            'Fale comigo no Discord',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(
          'ou me procure no jogo, nick duhit.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 14),
        ),
      ],
    ),
  );
}
