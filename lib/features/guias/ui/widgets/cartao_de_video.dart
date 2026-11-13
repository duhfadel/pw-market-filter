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
  const GrelhaDeVideos({
    required this.videos,
    this.compacta = false,
    this.depois,
    super.key,
  });

  final List<Video> videos;

  /// A forma que a banda do canal usa: `.fila { repeat(3,1fr); gap:12px }`,
  /// com cartões sem chão próprio — só a miniatura e duas linhas por baixo.
  ///
  /// **Um parâmetro e não um segundo cartão.** O que muda entre as duas
  /// formas é a moldura e o tamanho da letra; o que não muda é a miniatura
  /// 16:9, o botão de play, o título em duas linhas e a data. Dois widgets
  /// para isso divergiam na primeira vez que alguém mexesse num.
  final bool compacta;

  /// Um lugar extra no fim da fila — na banda do canal, o *o próximo está a
  /// caminho*. Fica aqui e não no chamador porque é parte da grelha: pôr um
  /// terceiro item numa `Row` ao lado não lhe daria a mesma largura.
  final Widget? depois;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      // **A fila compacta mede-se, a grelha grande tem proporcao fixa.**
      // Uma proporcao fixa nao serve na fila: a miniatura escala com a
      // largura e as linhas por baixo nao, portanto a mesma razao que cabe a
      // 180 px transborda a 140 -- foi assim, com 5,9 px, que a suite o
      // apanhou. Numa fila de tres a altura e a do mais alto, e uma `Row`
      // com `IntrinsicHeight` da exactamente isso sem numero a adivinhar.
      if (compacta) {
        final itens = <Widget>[
          for (final video in videos)
            CartaoDeVideo(video: video, compacto: true),
          ?depois,
        ];
        // Empilha num telemovel: tres colunas a 390 px dariam 120 px de
        // miniatura, onde nao se ve o que o video mostra.
        if (limites.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < itens.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                itens[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < itens.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: itens[i]),
              ],
            ],
          ),
        );
      }

      // Pela largura disponivel e nao pelo `wide` da pagina, o mesmo que a
      // grelha de destaques faz: uma coluna a 390 px mostra a miniatura
      // inteira, e tres cabem acima de 900.
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
          // A miniatura (16:9) mais o espaco das tres linhas por baixo. O
          // valor e medido e nao estimado: a 16/12.6 o cartao transbordava
          // 7,1 px assim que o titulo ia a duas linhas e havia detalhes -- e
          // isso com as fontes reais, portanto defeito e nao artefacto do
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
  const CartaoDeVideo({required this.video, this.compacto = false, super.key});

  final Video video;

  /// Sem moldura nem chão próprio, e com a letra mais pequena. Ver
  /// [GrelhaDeVideos.compacta].
  final bool compacto;

  /// `Bárbaro · gsafoot · 12/10/2026`, sem separadores soltos onde faltar
  /// um dos três — um `·` a abrir a linha é o que acontece quando se junta
  /// campos vazios sem olhar.
  String get _quem =>
      [?video.classe, ?video.personagem, ?video.dataEscrita].join('  ·  ');

  @override
  Widget build(BuildContext context) => Material(
    // Compacto não tem chão: `.vid` na maquete é só a miniatura e duas
    // linhas, sem moldura à volta — é o painel do canal que faz de moldura.
    color: compacto ? Colors.transparent : PWColors.surface,
    borderRadius: BorderRadius.circular(compacto ? 9 : 12),
    clipBehavior: compacto ? Clip.none : Clip.antiAlias,
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
          ClipRRect(
            // `.vid .thumb { border-radius: 9px }` — no compacto só a
            // miniatura é que tem cantos, porque o cartão não tem corpo.
            borderRadius: BorderRadius.circular(compacto ? 9 : 0),
            child: AspectRatio(
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
                  Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      // `.play { width: 34px }` na fila do canal.
                      size: compacto ? 34 : 46,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: compacto
                ? const EdgeInsets.only(top: 8)
                : const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                    style: TextStyle(
                      color: PWColors.text,
                      // `.vid .vt { font-size: 12.5px }`.
                      fontSize: compacto ? 12.5 : 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                // Duas linhas por baixo do título, cada uma a responder a uma
                // pergunta diferente: *quem gravou e quando*, depois *qual foi
                // a guerra*. Juntas numa só, a segunda metade seria sempre a
                // que o `ellipsis` comeria.
                if (_quem.isNotEmpty) ...[
                  SizedBox(height: compacto ? 3 : 4),
                  Text(
                    _quem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PWColors.textMuted,
                      // `.vid .vd { font-size: 11px }`.
                      fontSize: compacto ? 11 : 12,
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
