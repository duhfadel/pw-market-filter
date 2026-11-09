import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
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
        widget.carregar ?? () => VideoRepository().daSecao(CanalDoPortal.secao);
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
          child: widget.wide
              ? Row(
                  // `.canal.larga { align-items: center }` — o convite senta
                  // no meio do que a fila de videos ocupa, em vez de ficar
                  // encostado ao topo com meio painel vazio por baixo.
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // `grid-template-columns: 1fr 1.15fr; gap: 30px`.
                    const Expanded(flex: 100, child: _Convite(wide: true)),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 115,
                      child: GrelhaDeVideos(
                        videos: _videos,
                        compacta: true,
                        depois: const _Vago(),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Convite(wide: false),
                    const SizedBox(height: 18),
                    GrelhaDeVideos(
                      videos: _videos,
                      compacta: true,
                      depois: const _Vago(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// O que o painel diz, e a porta para o canal.
class _Convite extends StatelessWidget {
  const _Convite({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'O CANAL DO PORTAL PW',
        style: TextStyle(
          fontFamily: PWTheme.display,
          color: PWColors.apagado,
          fontSize: 13,
          letterSpacing: 2.6,
        ),
      ),
      SizedBox(height: wide ? 14 : 10),
      // Sem algarismos: a Marcellus desenha figuras romanas.
      ConstrainedBox(
        // `.canal.larga h3 { max-width: 16ch }` — duas linhas, como na
        // maquete, em vez de uma que corre até ao fim da coluna.
        constraints: BoxConstraints(maxWidth: wide ? 340 : double.infinity),
        child: Text(
          'Os primeiros já estão no ar',
          style: TextStyle(
            fontFamily: PWTheme.display,
            fontSize: wide ? 28 : 26,
            color: PWColors.papel,
            height: 1.15,
          ),
        ),
      ),
      SizedBox(height: wide ? 12 : 9),
      ConstrainedBox(
        // `.canal p { max-width: 44ch }`.
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(
          'Os guias em vídeo, as contas que ninguém faz à mão e o que o '
          'mercado anda dizendo.',
          style: TextStyle(
            color: PWColors.apagado,
            fontSize: wide ? 14 : 13,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: wide ? 18 : 14),
      const _Botao(),
    ],
  );
}

/// A porta para o canal, no mesmo separador como todo o link externo daqui.
class _Botao extends StatelessWidget {
  const _Botao();

  static const _canal = 'https://www.youtube.com/@PortalPw';

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton(
      onPressed: () => unawaited(
        launchUrl(Uri.parse(_canal), mode: LaunchMode.externalApplication),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: PWColors.papel,
        side: const BorderSide(color: PWColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: PWColors.surface.withValues(alpha: 0.5),
      ),
      child: const Text('Inscrever no YouTube →'),
    ),
  );
}

/// O lugar que ainda não tem vídeo.
///
/// ```css
/// .vago { aspect-ratio:16/9; border:1px dashed rgba(255,180,84,.34);
///         border-radius:10px; background:rgba(255,180,84,.03) }
/// ```
///
/// **Enche a terceira coluna e diz porquê.** Sem ele a fila ficava com um
/// buraco do tamanho de um cartão e o convite à esquerda ficava com meio
/// painel vazio ao lado — que foi o que o dono viu. Tracejado e não cheio,
/// porque promete e não entrega: é um lugar guardado, não um vídeo.
///
/// **Não promete data.** *Está a caminho* é verdade sobre a intenção de quem
/// grava; *«todas as semanas»* seria uma cadência que ninguém garantiu, e uma
/// promessa falhada numa página de entrada custa mais do que o lugar vazio
/// que ela tapava.
class _Vago extends StatelessWidget {
  const _Vago();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: DottedBorder(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'o próximo',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'está a caminho',
            style: TextStyle(
              color: PWColors.accent.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Uma moldura tracejada, que o Flutter não tem de origem.
class DottedBorder extends StatelessWidget {
  const DottedBorder({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _Tracejado(),
    child: ColoredBox(
      color: PWColors.accent.withValues(alpha: 0.03),
      child: child,
    ),
  );
}

class _Tracejado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final caneta = Paint()
      ..color = PWColors.accent.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const raio = Radius.circular(10);
    final caminho = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, raio));
    // Seis píxeis desenhados, quatro de intervalo — a cadência que lê como
    // tracejado sem virar pontilhado a esta espessura.
    for (final metrica in caminho.computeMetrics()) {
      var d = 0.0;
      while (d < metrica.length) {
        final ate = (d + 6).clamp(0.0, metrica.length);
        canvas.drawPath(metrica.extractPath(d, ate), caneta);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
