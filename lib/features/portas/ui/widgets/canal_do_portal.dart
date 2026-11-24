import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../../core/ui/cabeca_de_seccao.dart';
import '../../../guias/data/video_repository.dart';
import '../../../guias/domain/video.dart';
import '../../../guias/ui/widgets/cartao_de_video.dart';

/// Os vídeos do canal do Portal PW, na raiz.
///
/// **É do site e não de uma versão**, e é por isso que vive aqui e não se
/// repete na tela de cada mercado. A spec diz isso com uma linha: *«O canal do
/// Portal não se repete aqui. É do site e não desta versão.»*
///
/// **Sem pílula no cabeçalho.** Uma entrada de navegação para uma secção da
/// mesma página, de um canal com dois vídeos, é promessa a mais — a pílula
/// entra no dia em que houver vídeos que bastem e uma página a listá-los.
/// *Novidades* tem a sua porque muda sozinha e tem o ponto a avisar.
///
/// **Carrega sozinha e falha calada.** Como a faixa dos streamers: é uma
/// secção a somar, não a razão de alguém ter vindo, e uma secção que grita ao
/// falhar é pior do que uma que se cala. Sem vídeos não desenha nada — e
/// **nem o espaço**, que é a mesma razão pela qual `AoVivoStrip.espacoAcima`
/// existe.
class CanalDoPortal extends StatefulWidget {
  const CanalDoPortal({
    required this.wide,
    this.espacoAcima = 0,
    this.carregar,
    super.key,
  });

  final bool wide;
  final double espacoAcima;

  /// Por onde os vídeos chegam. Injectável só para o teste; **a secção monta
  /// o repositório ela própria**, como `TelaDeVideos` já faz — foi um `getIt`
  /// em falta, engolido por um `unawaited`, que deixou esta mesma tela a
  /// girar para sempre em 02/10/2026.
  final Future<List<Video>> Function()? carregar;

  /// A secção da tabela `videos` que guarda os vídeos do próprio Portal.
  static const secao = 'canal';

  @override
  State<CanalDoPortal> createState() => _CanalDoPortalState();
}

class _CanalDoPortalState extends State<CanalDoPortal> {
  List<Video> _videos = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final buscar =
        widget.carregar ??
        // `curada`: a apresentação fica fixa no topo (ordem baixa) e o resto
        // segue por recência — ao contrário das guerras, que são por data.
        () => VideoRepository().daSecao(CanalDoPortal.secao, curada: true);
    try {
      final videos = await buscar();
      if (!mounted) return;
      setState(() => _videos = videos);
    } catch (_) {
      // Fica vazia, e a secção desaparece. Ver a nota da classe.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.espacoAcima > 0) SizedBox(height: widget.espacoAcima),
        // **A régua vem por cima do painel e não dentro dele.** Dentro, ela
        // ficava na coluna do convite — 40% da largura — e o filete
        // transbordava 14 px a 772. A maquete põe `.cab` antes de
        // `.canal.larga`, e é também onde ela diz o que a secção é.
        const CabecaDeSeccao(titulo: 'O canal do Portal PW'),
        SizedBox(height: widget.wide ? 14 : 11),
        // **Um painel e não uma secção lisa**, e é a única coisa na raiz com
        // chão próprio. O canal é o que o site está a começar agora: a
        // moldura dá-lhe o peso de um anúncio sem precisar de o escrever.
        Container(
          padding: EdgeInsets.all(widget.wide ? 32 : 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PWColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // `linear-gradient(135deg, rgba(120,90,220,.16), chao 62%)`.
              // O roxo é exactamente `PWColors.glowViolet` (#785ADC) e o
              // chão é `surface` (#13132A) — os dois já existiam na paleta.
              stops: const [0, 0.62],
              colors: [
                PWColors.glowViolet.withValues(alpha: 0.16),
                PWColors.surface,
              ],
            ),
          ),
          // **O título é um letreiro à largura toda, e a fila de vídeos vem
          // por baixo dele — pedido do dono.** Antes o convite ficava numa
          // coluna à esquerda e os vídeos espremidos na outra metade; agora o
          // grito «FALHA TERRITORIAL…» abre o painel de ponta a ponta, o
          // subtítulo e o botão ficam numa linha, e os vídeos ocupam toda a
          // largura em baixo, com as miniaturas maiores.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Titulo(),
              SizedBox(height: widget.wide ? 16 : 13),
              // O subtítulo e o botão lado a lado no largo; empilhados no
              // estreito, onde não cabem na mesma linha.
              if (widget.wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Expanded(child: _Subtitulo(wide: true)),
                    SizedBox(width: 20),
                    _Botao(),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Subtitulo(wide: false),
                    SizedBox(height: 14),
                    _Botao(),
                  ],
                ),
              SizedBox(height: widget.wide ? 24 : 20),
              // `compacta` já é a fila horizontal (miniatura 16:9 em cima,
              // título e data por baixo), e empilha sozinha no telemóvel. Com
              // a largura toda do painel, os quatro cartões ficam lado a lado.
              GrelhaDeVideos(videos: _videos, compacta: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// O letreiro do canal, à largura toda.
///
/// **Os A's esticados são o grito, e é pedido do dono** — o canal é informal,
/// e o título abre o painel de ponta a ponta como uma manchete. `scaleDown`
/// com alinhamento à esquerda: num ecrã largo fica no tamanho base, num
/// estreito encolhe até caber, nunca corta uma letra. Sem algarismos, que a
/// Marcellus desenha como figuras romanas — e aqui não há nenhum.
class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        'FALHA TERRITORIAAAAAAAAAAAAAAL',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: 46,
          color: PWColors.papel,
          height: 1,
        ),
      ),
    ),
  );
}

/// A linha que diz o que o canal é, por baixo do letreiro.
class _Subtitulo extends StatelessWidget {
  const _Subtitulo({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Text(
    'Os melhores e os piores momentos do competitivo!',
    style: TextStyle(
      color: PWColors.apagado,
      fontSize: wide ? 15 : 14,
      height: 1.4,
    ),
  );
}

/// A porta para o canal — **vermelho do YouTube, a pedido do dono**, para o
/// convite a inscrever-se chamar o olho. É o único botão cheio e vivo da raiz,
/// e é deliberado: nada mais aqui disputa a atenção com ele.
class _Botao extends StatelessWidget {
  const _Botao();

  static const _canal = 'https://www.youtube.com/@PortalPw';

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () => unawaited(
      launchUrl(Uri.parse(_canal), mode: LaunchMode.externalApplication),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: PWColors.youtube,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: const Text(
      'Inscrever no YouTube →',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
