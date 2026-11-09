/// A grelha de vídeos e o cartão dela.
///
/// **Extraídos de `tela_de_videos.dart` a 09/11/2026**, quando a raiz ganhou
/// a banda do canal do Portal e passou a haver um segundo chamador. Copiar o
/// cartão seria a segunda cópia que este repositório já pagou três vezes —
/// `_abrir` e `_openTool` byte a byte iguais, duas listas de guias que não se
/// conheciam, dois escritores de `versoes.json`.
///
/// Nada aqui sabe de busca nem de filtro por classe: isso é da tela, e é o
/// que torna a grelha reutilizável por uma banda de dois vídeos.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/video.dart';

class GrelhaDeVideos extends StatelessWidget {
  const GrelhaDeVideos({required this.videos, super.key});

  final List<Video> videos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      // Pela largura disponível e não pelo `wide` da página, o mesmo que a
      // grelha de destaques faz: uma coluna a 390 px mostra a miniatura
      // inteira, e três cabem acima de 900.
      final colunas = limites.maxWidth >= 900
          ? 3
          : limites.maxWidth >= 600
          ? 2
          : 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunas,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          // A miniatura (16:9) mais o espaço das três linhas por baixo. O
          // valor é medido e não estimado: a 16/12.6 o cartão transbordava
          // 7,1 px assim que o título ia a duas linhas e havia detalhes — e
          // isso com as fontes reais, portanto defeito e não artefacto do
          // harness.
          childAspectRatio: 16 / 13.6,
        ),
        itemCount: videos.length,
        itemBuilder: (_, i) => CartaoDeVideo(video: videos[i]),
      );
    },
  );
}

class CartaoDeVideo extends StatelessWidget {
  const CartaoDeVideo({required this.video, super.key});

  final Video video;

  /// `Bárbaro · gsafoot · 12/10/2026`, sem separadores soltos onde faltar
  /// um dos três — um `·` a abrir a linha é o que acontece quando se junta
  /// campos vazios sem olhar.
  String get _quem =>
      [?video.classe, ?video.personagem, ?video.dataEscrita].join('  ·  ');

  @override
  Widget build(BuildContext context) => Material(
    color: PWColors.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => unawaited(
        launchUrl(
          Uri.parse(video.endereco),
          mode: LaunchMode.externalApplication,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video.miniatura,
                  fit: BoxFit.cover,
                  // Uma miniatura que não carrega deixa a moldura escura e o
                  // título a falar — nunca uma caixa partida, o mesmo recuo
                  // silencioso que `ItemIcon` faz.
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: PWColors.surfaceRaised),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 46,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A manchete é o título, ou os detalhes quando não há
                // título — ver `Video.manchete`. Um card sem nenhum dos dois
                // abre pela linha de quem-e-quando em vez de por um espaço
                // vazio com a altura de duas linhas.
                if (video.manchete case final manchete?)
                  Text(
                    manchete,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                // Duas linhas por baixo do título, cada uma a responder a uma
                // pergunta diferente: *quem gravou e quando*, depois *qual foi
                // a guerra*. Juntas numa só, a segunda metade seria sempre a
                // que o `ellipsis` comeria.
                if (_quem.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _quem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (video.detalhesPorBaixo case final detalhes?) ...[
                  const SizedBox(height: 2),
                  Text(
                    detalhes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.papel,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
