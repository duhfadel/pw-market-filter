import 'dart:math' as math;

import 'package:flutter/material.dart';

/// As brasas que sobem por cima da arte do herói.
///
/// **Copiadas da maquete**, que as desenha num `<canvas class="ceu">`:
/// cinquenta e quatro partículas com raio, velocidade, opacidade e fase
/// próprias, mais cinco faixas de bruma a atravessar devagar.
///
/// **São pintadas e não um ficheiro, e a diferença é grande.** Um GIF ou um
/// WebP animado do tamanho do herói — 1440×760, e 2880×1520 num ecrã Retina —
/// são megabytes que cada visitante descarrega, contra cinquenta e quatro
/// círculos por frame que não pesam nada. Um ficheiro de tamanho fixo também
/// não se adapta à janela: esticado, distorce as partículas. E o GIF tem alfa
/// de um bit, que serrilharia brilhos suaves sobre a arte.
///
/// **O preço é `pumpAndSettle`, e foi pago em vez de contornado.** Qualquer
/// animação permanente agenda frames para sempre, portanto `pumpAndSettle`
/// nunca termina numa página que a contenha — foi o que o ponto a pulsar fez
/// a 09/11/2026, com trinta e seis testes caídos de uma vez. Os testes que
/// montam o herói esperam por tempo agora, com `pump(Duration)`, que é o que
/// se faz em qualquer aplicação com movimento ambiente.
///
/// **E param quando o sistema pede.** `MediaQuery.disableAnimationsOf` é a
/// preferência de quem desligou o movimento no sistema operativo — não é um
/// atalho para testes, é a resposta certa a quem tem enxaqueca ou vertigem
/// com movimento na periferia.
class Brasas extends StatefulWidget {
  const Brasas({super.key});

  /// `brasas = Array.from({length: 54})` na maquete.
  static const quantas = 54;

  /// Quanto tempo uma brasa leva a atravessar o herói de baixo a cima. Cada
  /// uma tem a sua velocidade; isto é o relógio comum.
  static const volta = Duration(seconds: 14);

  @override
  State<Brasas> createState() => _BrasasState();
}

class _BrasasState extends State<Brasas> with SingleTickerProviderStateMixin {
  late final AnimationController _relogio = AnimationController(
    vsync: this,
    duration: Brasas.volta,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parado = MediaQuery.disableAnimationsOf(context);
    if (parado) {
      _relogio.stop();
    } else if (!_relogio.isAnimating) {
      _relogio.repeat();
    }
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _relogio,
      builder: (context, _) =>
          CustomPaint(painter: _Pintor(_relogio.value), size: Size.infinite),
    ),
  );
}

/// O ruído determinístico da maquete, à letra:
/// `R(a,b,n) = a + fract(sin(n*127.1) * 43758.5453) * (b-a)`.
///
/// **Determinístico e não `Random()`**, pela mesma razão que a classe do
/// herói deriva da data da coleta: um campo de brasas que muda a cada
/// reconstrução faria a página piscar de outra maneira a cada frame.
double _r(double a, double b, int n) {
  final t = math.sin(n * 127.1) * 43758.5453;
  return a + (t - t.floorToDouble()) * (b - a);
}

class _Pintor extends CustomPainter {
  const _Pintor(this.fase);

  /// 0 a 1, uma volta completa do relógio comum.
  final double fase;

  @override
  void paint(Canvas canvas, Size size) {
    final caneta = Paint();

    // As cinco faixas de bruma, por baixo das brasas.
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.55 + i * 0.09);
      final alfa = _r(0.03, 0.08, i + 2);
      final v = _r(0.04, 0.12, i + 4);
      final x = (_r(0, 1, i + 6) + fase * v * 6) % 1.4 - 0.2;
      canvas.drawRect(
        Rect.fromLTWH(x * size.width, y, size.width * 0.55, 2),
        caneta
          ..color = const Color(0xFFFFD6A0).withValues(alpha: alfa)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    caneta.maskFilter = null;
    for (var i = 1; i <= Brasas.quantas; i++) {
      final raio = _r(0.5, 2.4, i + 3);
      final v = _r(0.07, 0.4, i + 5);
      final opacidade = _r(0.12, 0.6, i + 7);
      final balanco = _r(0, 6.3, i + 11);

      // Sobe e dá a volta por baixo: `(y - v*t) mod h`, como o canvas faz.
      final y0 = _r(0, 1, i + 9);
      final y = ((y0 - fase * v * 8) % 1.0 + 1.0) % 1.0;
      // Um bamboleio lateral, para não subirem em linhas rectas.
      final x = _r(0, 1, i) + math.sin(balanco + fase * 6.3) * 0.012;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        raio,
        caneta
          ..color = const Color(0xFFFFB454).withValues(
            // Apagam-se ao chegar ao topo, para não cortarem a direito.
            alpha: opacidade * (y < 0.12 ? y / 0.12 : 1),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Pintor anterior) => anterior.fase != fase;
}
