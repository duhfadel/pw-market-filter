import 'package:flutter/material.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../../../../home/domain/visit_label.dart' show groupThousands;
import '../../../domain/financeiro/calculos.dart';
import '../dinheiro.dart';

/// Abbreviated month names, 1-indexed like [MesFinanceiro.mes] so `mes - 1`
/// is the only arithmetic this file needs to label a bar group.
const _nomesDosMeses = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

/// The month-by-month chart: three grouped bars per month — entrada,
/// despesa, pagamento de staff — and a dashed reference line for the
/// current `gastoFixo`.
///
/// A [CustomPainter] rather than a charting package, per the brief: this
/// repository adds no dependency for a dozen rectangles, a dashed line and
/// a handful of labels.
class GraficoFin extends StatelessWidget {
  const GraficoFin({required this.meses, required this.gastoFixo, super.key});

  final List<MesFinanceiro> meses;
  final int gastoFixo;

  static const _alturaGrafico = 220.0;

  /// Below this, a month's three bars and its label have no room to breathe
  /// — the chart scrolls horizontally instead of squeezing them.
  static const _larguraMinimaPorMes = 72.0;

  @override
  Widget build(BuildContext context) {
    if (meses.isEmpty) {
      return Container(
        height: _alturaGrafico,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PWColors.painel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PWColors.filete),
        ),
        child: const Text(
          'Sem lançamentos ainda.',
          style: TextStyle(color: PWColors.apagado),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legenda(gastoFixo: gastoFixo),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final larguraDisponivel = constraints.maxWidth;
            final larguraNecessaria = meses.length * _larguraMinimaPorMes;
            // Fit to the available width when it is enough; otherwise give
            // every month its minimum and let the row scroll instead of
            // crushing the bars together.
            final largura = larguraNecessaria > larguraDisponivel
                ? larguraNecessaria
                : larguraDisponivel;

            final grafico = SizedBox(
              width: largura,
              height: _alturaGrafico,
              child: CustomPaint(
                painter: _PintorFin(meses: meses, gastoFixo: gastoFixo),
              ),
            );

            if (larguraNecessaria > larguraDisponivel) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: grafico,
              );
            }
            return grafico;
          },
        ),
      ],
    );
  }
}

/// The three bar colours and the gasto-fixo line, named once so the chart
/// and the legend can never disagree about which colour means what.
class _Legenda extends StatelessWidget {
  const _Legenda({required this.gastoFixo});

  final int gastoFixo;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const _ItemLegenda(cor: PWColors.ok, rotulo: 'Entrada'),
      const _ItemLegenda(cor: PWColors.danger, rotulo: 'Despesa'),
      const _ItemLegenda(cor: PWColors.male, rotulo: 'Staff'),
      _ItemLegenda(
        cor: PWColors.accent,
        rotulo: 'Gasto fixo · ${tcc(gastoFixo)}',
        tracejado: true,
      ),
    ],
  );
}

class _ItemLegenda extends StatelessWidget {
  const _ItemLegenda({
    required this.cor,
    required this.rotulo,
    this.tracejado = false,
  });

  final Color cor;
  final String rotulo;
  final bool tracejado;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (tracejado)
        CustomPaint(
          size: const Size(14, 2),
          painter: _LinhaTracejadaPainter(cor: cor),
        )
      else
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      const SizedBox(width: 6),
      Text(
        rotulo,
        style: const TextStyle(color: PWColors.apagado, fontSize: 12),
      ),
    ],
  );
}

class _LinhaTracejadaPainter extends CustomPainter {
  const _LinhaTracejadaPainter({required this.cor});

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = 2;
    const dash = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dash, size.height / 2),
        paint,
      );
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaTracejadaPainter oldDelegate) =>
      oldDelegate.cor != cor;
}

/// Draws the grouped bars, the gasto-fixo reference line, the month labels
/// and a couple of y-axis gridlines.
class _PintorFin extends CustomPainter {
  _PintorFin({required this.meses, required this.gastoFixo});

  final List<MesFinanceiro> meses;
  final int gastoFixo;

  static const _paddingEsquerda = 48.0;
  static const _paddingDireita = 8.0;
  static const _paddingTopo = 8.0;
  static const _paddingBaixo = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final larguraUtil = size.width - _paddingEsquerda - _paddingDireita;
    final alturaUtil = size.height - _paddingTopo - _paddingBaixo;
    final baseY = _paddingTopo + alturaUtil;

    final maiorValor = _maiorValor();
    final escala = maiorValor == 0 ? 0.0 : alturaUtil / maiorValor;

    _desenharGrade(canvas, maiorValor, baseY, alturaUtil, larguraUtil);
    _desenharBarras(canvas, escala, baseY, larguraUtil);
    _desenharGastoFixo(canvas, escala, baseY, larguraUtil);
    _desenharRotulosMes(canvas, baseY, larguraUtil);
  }

  int _maiorValor() {
    var maior = gastoFixo;
    for (final m in meses) {
      if (m.entrada > maior) maior = m.entrada;
      if (m.despesa > maior) maior = m.despesa;
      if (m.staff > maior) maior = m.staff;
    }
    return maior;
  }

  void _desenharGrade(
    Canvas canvas,
    int maiorValor,
    double baseY,
    double alturaUtil,
    double larguraUtil,
  ) {
    final linha = Paint()
      ..color = PWColors.filete
      ..strokeWidth = 1;

    for (final fracao in [0.0, 0.5, 1.0]) {
      final y = baseY - alturaUtil * fracao;
      canvas.drawLine(
        Offset(_paddingEsquerda, y),
        Offset(_paddingEsquerda + larguraUtil, y),
        linha,
      );
      final valor = (maiorValor * fracao).round();
      _escreverTexto(
        canvas,
        groupThousands(valor),
        Offset(0, y - 6),
        largura: _paddingEsquerda - 6,
        alinhamento: TextAlign.right,
      );
    }
  }

  void _desenharBarras(
    Canvas canvas,
    double escala,
    double baseY,
    double larguraUtil,
  ) {
    final larguraGrupo = larguraUtil / meses.length;
    final larguraAreaBarras = larguraGrupo * 0.7;
    final larguraBarra = larguraAreaBarras / 3;
    final folga = (larguraGrupo - larguraAreaBarras) / 2;

    for (var i = 0; i < meses.length; i++) {
      final mes = meses[i];
      final esquerdaGrupo = _paddingEsquerda + i * larguraGrupo + folga;

      _desenharBarra(
        canvas,
        esquerdaGrupo,
        larguraBarra,
        mes.entrada,
        escala,
        baseY,
        PWColors.ok,
      );
      _desenharBarra(
        canvas,
        esquerdaGrupo + larguraBarra,
        larguraBarra,
        mes.despesa,
        escala,
        baseY,
        PWColors.danger,
      );
      _desenharBarra(
        canvas,
        esquerdaGrupo + larguraBarra * 2,
        larguraBarra,
        mes.staff,
        escala,
        baseY,
        PWColors.male,
      );
    }
  }

  void _desenharBarra(
    Canvas canvas,
    double esquerda,
    double largura,
    int valor,
    double escala,
    double baseY,
    Color cor,
  ) {
    final altura = valor * escala;
    if (altura <= 0) return;
    final rect = Rect.fromLTRB(
      esquerda,
      baseY - altura,
      esquerda + largura,
      baseY,
    );
    canvas.drawRect(rect, Paint()..color = cor);
  }

  void _desenharGastoFixo(
    Canvas canvas,
    double escala,
    double baseY,
    double larguraUtil,
  ) {
    if (gastoFixo <= 0) return;
    final y = baseY - gastoFixo * escala;
    final paint = Paint()
      ..color = PWColors.accent
      ..strokeWidth = 2;
    const dash = 6.0;
    var x = _paddingEsquerda;
    while (x < _paddingEsquerda + larguraUtil) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash * 1.6;
    }
  }

  void _desenharRotulosMes(Canvas canvas, double baseY, double larguraUtil) {
    final larguraGrupo = larguraUtil / meses.length;
    for (var i = 0; i < meses.length; i++) {
      final mes = meses[i];
      final nome = _nomesDosMeses[(mes.mes - 1).clamp(0, 11)];
      final centro = _paddingEsquerda + i * larguraGrupo + larguraGrupo / 2;
      _escreverTexto(
        canvas,
        nome,
        Offset(centro - larguraGrupo / 2, baseY + 6),
        largura: larguraGrupo,
        alinhamento: TextAlign.center,
      );
    }
  }

  void _escreverTexto(
    Canvas canvas,
    String texto,
    Offset offset, {
    required double largura,
    required TextAlign alinhamento,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(color: PWColors.apagado, fontSize: 11),
      ),
      textAlign: alinhamento,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: largura);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PintorFin oldDelegate) =>
      oldDelegate.meses != meses || oldDelegate.gastoFixo != gastoFixo;
}
