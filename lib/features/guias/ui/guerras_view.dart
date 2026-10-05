import 'package:flutter/material.dart';

import '../../../core/rotas.dart' as rotas;
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../domain/video.dart';
import 'tela_de_videos.dart';

/// Os vídeos de guerra territorial que a comunidade autorizou.
///
/// **A política é o conteúdo aqui.** A página só tem vídeo porque alguém se
/// ofereceu — nada é garimpado — e por isso o convite fica sempre visível, no
/// fim da grelha, e não apenas quando não há nada. Escondê-lo depois de entrar
/// o primeiro vídeo seria fechar a porta por onde a página se enche.
class GuerrasView extends StatelessWidget {
  const GuerrasView({this.versao = rotas.pw187, this.carregar, super.key});

  /// Qual mercado. **As guerras existem nos dois**, e a versão é o que decide
  /// quais vídeos pedir e o que a barra mostra — um vídeo de guerra do 1.8.7
  /// debaixo do 1.2.6 seria o site a dizer que aquilo é de lá.
  final String versao;

  final Future<List<Video>> Function()? carregar;

  @override
  Widget build(BuildContext context) => TelaDeVideos(
    secao: 'guerras',
    versao: versao,
    dicaDeBusca: 'Buscar por guilda, personagem ou título',
    carregar: carregar,
    cabecalho: _Cabecalho(versao: versao),
  );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.versao});

  final String versao;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Sem algarismos, portanto a face de display é segura aqui: Marcellus
      // desenha figuras romanas e o seu `1` não tem bandeira.
      const Text(
        'Guerras Territoriais',
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: 32,
          color: PWColors.papel,
          height: 1.15,
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Vídeos de guerra territorial do $versao — para rever como foi a '
        'guerra, analisar a gameplay ou comparar com a sua.',
        style: const TextStyle(
          color: PWColors.textMuted,
          fontSize: 14,
          height: 1.55,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Todos os jogadores que têm seus vídeos aqui me deram permissão '
        'para tal.',
        style: TextStyle(color: PWColors.papel, fontSize: 14, height: 1.55),
      ),
    ],
  );
}
