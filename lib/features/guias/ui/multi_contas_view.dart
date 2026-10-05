import 'package:flutter/material.dart';

import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../domain/video.dart';
import 'tela_de_videos.dart';

/// O guia de multi contas: jogar com mais de um cliente aberto ao mesmo
/// tempo.
///
/// **Sem gémea do 1.2.6, ao contrário das Guerras.** O que obrigou as guerras
/// a terem duas rotas foi os vídeos serem de um mercado ou do outro; um guia
/// escrito uma vez não existe duas, e pedir os vídeos por versão esconderia
/// as linhas de quem deixasse a coluna em branco. Daí
/// `filtrarPorVersao: false`.
class MultiContasView extends StatelessWidget {
  const MultiContasView({this.carregar, super.key});

  final Future<List<Video>> Function()? carregar;

  @override
  Widget build(BuildContext context) => TelaDeVideos(
    secao: 'multicontas',
    filtrarPorVersao: false,
    carregar: carregar,
    cabecalho: const _Cabecalho(),
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sem algarismos, portanto a face de display é segura aqui: Marcellus
      // desenha figuras romanas e o seu `1` não tem bandeira.
      Text(
        'Multi contas',
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: 32,
          color: PWColors.papel,
          height: 1.15,
        ),
      ),
      SizedBox(height: 10),
      // **A ferramenta tem nome e o nome é o que se procura.** Quem chega
      // aqui quer saber como, e `TC Helper` é a palavra que resolve a busca
      // — por isso vem destacada em vez de diluída no meio da frase.
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  'No The Classic, usar mais de uma conta é permitido — e a '
                  'ferramenta para isso vem dentro do próprio launcher: o ',
            ),
            TextSpan(
              text: 'TC Helper',
              style: TextStyle(
                color: PWColors.papel,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  '. Nele você cadastra as suas contas e entra com um clique, '
                  'e ainda dá para montar macros e caçar sozinho com a sua '
                  'própria PT.',
            ),
          ],
        ),
        style: TextStyle(color: PWColors.textMuted, fontSize: 14, height: 1.55),
      ),
      SizedBox(height: 8),
      Text(
        'Abaixo, um vídeo do RomanZitto que explica com mais detalhes.',
        style: TextStyle(color: PWColors.papel, fontSize: 14, height: 1.55),
      ),
    ],
  );
}
