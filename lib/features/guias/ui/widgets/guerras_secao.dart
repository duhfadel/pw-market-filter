import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/ui/cabeca_de_seccao.dart';
import '../../../home/ui/widgets/tool_navigation.dart';
import '../../data/video_repository.dart';
import '../../domain/guerra_recente.dart';
import '../../domain/video.dart';
import 'convite_de_video.dart';

/// As guerras territoriais mais recentes, na home de um mercado.
///
/// **Os vídeos e não o mapa, e a maquete desenhava os dois.** O painel do
/// mapa saiu depois de medir a base a 10/11/2026: `max(atualizado_em)` nos 52
/// territórios dá **18/08/2026** e só **16** têm dono, portanto aquele painel
/// imprimiria *«última conquista: 18 de agosto»* na primeira dobra. O
/// *«2 de novembro»* da maquete foi escrito à mão para ela ficar apresentável
/// e nunca foi lido de lado nenhum.
///
/// E há a razão que decide sozinha: **`/guerras/` foi retirada de propósito a
/// 29/09/2026** e as duas páginas carregam `noindex`. `tool.dart` diz o que
/// custa trazê-la de volta — *«três gestos que andam juntos, e fazer um só
/// deixa o site incoerente consigo mesmo»*. Uma porta a partir daqui seria
/// exactamente um desses três.
///
/// **Carrega sozinha e falha calada**, como [CanalDoPortal] e a faixa dos
/// streamers. Mas falhar e estar vazia são coisas diferentes aqui, e é essa a
/// distinção que [_estado] existe para guardar: um mercado sem vídeo nenhum
/// mostra o convite, e um pedido que não chegou não mostra nada. Dizer *«não
/// temos vídeos»* por causa de um erro de rede seria afirmar sobre o acervo
/// uma coisa que só se sabe sobre a ligação.
class GuerrasSecao extends StatefulWidget {
  const GuerrasSecao({
    required this.versao,
    required this.wide,
    this.carregar,
    super.key,
  });

  /// Qual mercado. **As guerras existem nos dois**, e é a versão que decide
  /// quais vídeos pedir — um vídeo de guerra do 1.8.7 debaixo do 1.2.6 seria
  /// o site a dizer que aquilo é de lá.
  final String versao;

  final bool wide;

  /// Injectável só para o teste; **a secção monta o repositório ela
  /// própria**, como `TelaDeVideos` e `CanalDoPortal` já fazem — foi um
  /// `getIt` em falta, engolido por um `unawaited`, que deixou a tela de
  /// vídeos a girar para sempre em 02/10/2026.
  final Future<List<Video>> Function()? carregar;

  /// Quantas guerras a home mostra. Quatro, como a maquete: o suficiente para
  /// se ver que há movimento, e a porta no fim leva às 47.
  static const quantas = 4;

  @override
  State<GuerrasSecao> createState() => _GuerrasSecaoState();
}

enum _Estado { aCarregar, falhou, pronto }

class _GuerrasSecaoState extends State<GuerrasSecao> {
  _Estado _estado = _Estado.aCarregar;
  List<GuerraRecente> _guerras = const [];
  int _videos = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final buscar =
        widget.carregar ??
        () => VideoRepository().daSecao('guerras', versao: widget.versao);
    try {
      final videos = await buscar();
      if (!mounted) return;
      setState(() {
        _estado = _Estado.pronto;
        _videos = videos.length;
        _guerras = guerrasRecentes(videos);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _estado = _Estado.falhou);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estado != _Estado.pronto) return const SizedBox.shrink();

    final mostradas = _guerras.take(GuerrasSecao.quantas).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecaDeSeccao(
          titulo: 'Vídeos de guerras territoriais',
          // A porta só aparece quando há o que abrir — num mercado sem vídeo
          // nenhum ela prometeria uma página vazia — e **só no largo**.
          //
          // Medido com as fontes reais a 10/11/2026: a cabeça passou de 191
          // px para **285** ao ganhar o *Vídeos de*, e com os dois vãos e a
          // porta dá 408 contra os ~350 que um ecrã de 390 deixa. É a mesma
          // conta que já tirou a porta à cabeça dos Destaques no estreito, e
          // o que se perde é pouco: a secção inteira é a lista, e tocar numa
          // linha abre o vídeo.
          // **Com o número, ao contrário dos guias**, e a diferença é que
          // aqui ele é verdade: os 47 são todos deste mercado, portanto
          // dizê-lo é informação. Nos guias o total era do site inteiro.
          porta: _videos == 0 || !widget.wide
              ? null
              : 'ver todos os $_videos →',
          // `/{versao}/guerras`, a mesma forma que `Tool.route` declara —
          // montada aqui a partir da versão em vez de passar pelo `Tool`,
          // porque o que esta porta tem na mão é o mercado e não a entrada
          // de menu.
          aoTocarNaPorta: _videos == 0 || !widget.wide
              ? null
              : () => abrirEndereco(
                  context,
                  '/${widget.versao}/guerras',
                  externo: false,
                ),
        ),
        SizedBox(height: widget.wide ? 14 : 11),
        if (mostradas.isEmpty)
          // **Pedido do dono a 10/11/2026**, contra o silêncio que eu tinha
          // proposto. Um mercado sem vídeo nenhum não é uma secção a menos: é
          // o sítio onde o convite tem mais trabalho a fazer, porque ali ele
          // explica o vazio em vez de somar a um acervo cheio.
          ConviteDeVideo(
            chamada:
                'Ainda não temos vídeos de guerra do ${widget.versao}. '
                'Podemos usar o seu?',
          )
        else
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.wide ? 20 : 16,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PWColors.border),
              color: PWColors.surface,
            ),
            child: Column(
              children: [
                for (final (i, guerra) in mostradas.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: PWColors.border),
                  _Linha(guerra: guerra, wide: widget.wide),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Uma guerra: o que foi, quem filmou, quando.
class _Linha extends StatelessWidget {
  const _Linha({required this.guerra, required this.wide});

  final GuerraRecente guerra;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final quem = guerra.quem;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (guerra.manchete case final manchete?)
                  Text(
                    manchete,
                    style: const TextStyle(
                      color: PWColors.papel,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (quem != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    quem,
                    style: const TextStyle(
                      color: PWColors.textMuted,
                      fontSize: 12.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (guerra.dataEscrita case final data?) ...[
            const SizedBox(width: 10),
            Text(
              // **Sem o ano, e só aqui.** A tela de Guerras imprime
              // `07/11/2026` porque lá se rola por um acervo de meses; esta
              // lista é *o que aconteceu agora* e o ano é a parte que nunca
              // distingue duas destas quatro linhas.
              data.substring(0, 5),
              style: const TextStyle(
                color: PWColors.textMuted,
                fontSize: 12.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
