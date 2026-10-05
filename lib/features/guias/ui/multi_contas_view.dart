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
      Text(
        'Jogar com mais de um cliente aberto ao mesmo tempo — o segundo '
        'personagem que dá buff, que carrega o que o primeiro não aguenta, '
        'ou que fica no mercado enquanto você joga.',
        style: TextStyle(color: PWColors.textMuted, fontSize: 14, height: 1.55),
      ),
    ],
  );
}
