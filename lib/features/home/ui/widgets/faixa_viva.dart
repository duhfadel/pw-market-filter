import 'package:flutter/material.dart';

import '../../../../core/theme/medidas_da_maquete.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../../market/market_index.dart';
import '../../../search/domain/search_query.dart';
import '../../domain/faixa_viva.dart';
import '../../domain/visit_label.dart' show groupThousands;

/// O mercado agora: um selo com o tamanho e a data, e três números que mudam
/// sozinhos — cada um uma porta para o filtro com a pergunta já feita.
///
/// **Escrita a partir do CSS da maquete**, como a faixa das versões na raiz:
///
/// ```css
/// .selo { display:flex; align-items:baseline; gap:10px }
/// .selo .q { font-size:11.5px; color:#5E5A7C; margin-left:auto }
/// .viva { border-top/bottom: 1px solid filete; background:#13132A }
/// .vb { padding:30px 10px 32px; text-align:center }
/// .vb+.vb { border-left:1px solid filete }
/// .vb .n { font-size:38px; font-weight:600; letter-spacing:-.02em }
/// .vb .r { font-size:13px; color:apagado; margin-top:9px }
/// .vb .r b { color: texto; font-weight:500 }
/// ```
///
/// **É a única coisa na página que muda sozinha todos os dias**, e é a
/// resposta ao *não convida a voltar*. `firstSeen` e `previousPrice` são
/// recolhidos desde 30/09/2026 e nunca tinham aparecido em tela nenhuma — a
/// forma de desperdício que este repositório já conhece pelo nome, depois do
/// `sexo` colhido em Agosto e mostrado em Outubro.
///
/// **O carimbo da coleta vem no selo e não debaixo dos números.** Um índice
/// velho parece exactamente igual a um fresco, e um filtro perfeito sobre
/// dados do mês passado é pior do que filtro nenhum.
class FaixaViva extends StatelessWidget {
  const FaixaViva({
    required this.index,
    required this.wide,
    required this.onAbrir,
    required this.larguraDaColuna,
    required this.margem,
    super.key,
  });

  final MarketIndex index;
  final bool wide;

  /// Abre o filtro já a responder à pergunta da figura tocada.
  final void Function(SearchQuery) onAbrir;

  final double larguraDaColuna;
  final double margem;

  /// Passada uma semana o carimbo acende. O mesmo limite que a tela do filtro
  /// usa — um só número, lido de um só lugar, para as duas telas não poderem
  /// discordar sobre o que é velho.
  static const diasAteEnvelhecer = 7;

  @override
  Widget build(BuildContext context) {
    final figuras = figurasVivas(index);
    final agora = DateTime.now();
    // Um só número para a cor e para as palavras. Lidos de sítios diferentes,
    // discordariam na fronteira — seis dias decorridos podem ser sete de
    // calendário — e a faixa acenderia a dizer «há 6 dias».
    final dias = diasDeCalendario(index.collectedAt, agora);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: larguraDaColuna),
            child: Padding(
              padding: EdgeInsets.fromLTRB(margem, 0, margem, 10),
              child: _Selo(index: index, dias: dias, wide: wide),
            ),
          ),
        ),
        _Banda(
          figuras: figuras,
          wide: wide,
          larguraDaColuna: larguraDaColuna,
          onAbrir: onAbrir,
        ),
      ],
    );
  }

  /// **«Hoje» é o dia do calendário e não vinte e quatro horas**, e a
  /// diferença morde: a coleta corre a cada meia hora, portanto um índice de
  /// ontem às 23:50 lido à 00:10 tem *zero* dias decorridos e não é de hoje.
  static int diasDeCalendario(DateTime quando, DateTime agora) => DateTime(
    agora.year,
    agora.month,
    agora.day,
  ).difference(DateTime(quando.year, quando.month, quando.day)).inDays;
}

/// `O MERCADO AGORA` à esquerda, o tamanho e a data à direita.
class _Selo extends StatelessWidget {
  const _Selo({required this.index, required this.dias, required this.wide});

  final MarketIndex index;
  final int dias;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final velho = dias >= FaixaViva.diasAteEnvelhecer;
    final carimbo = Text(
      _carimbo(index, dias),
      textAlign: wide ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        // `.selo .q { color:#5E5A7C }` — mais apagado do que `apagado`,
        // porque é contexto e não um dos números que se comparam. A não ser
        // quando envelhece, e aí tem de se ver.
        color: velho ? PWColors.accent : const Color(0xFF5E5A7C),
        fontSize: wide ? 11.5 : 10.5,
      ),
    );

    // **Empilha no telemóvel.** Lado a lado, a sobrancelha de quinze
    // caracteres mais o carimbo transbordavam 178 px a 390 — e a maquete não
    // tem este caso porque ali o `.selo` só existe na tela larga.
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_sobrancelha, const SizedBox(height: 3), carimbo],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _sobrancelha,
        const SizedBox(width: 10),
        Expanded(child: carimbo),
      ],
    );
  }

  /// Marcellus, e é seguro: não há algarismo nenhum nesta frase.
  static const _sobrancelha = Text(
    'O MERCADO AGORA',
    style: TextStyle(
      fontFamily: PWTheme.display,
      color: PWColors.apagado,
      fontSize: 13,
      letterSpacing: 2.6,
    ),
  );

  static String _carimbo(MarketIndex index, int dias) {
    final d = index.collectedAt.toLocal();
    final quantos = groupThousands(index.characters.length);
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    // Dentro do dia a hora diz mais do que a data: quem volta ao site quer
    // saber se isto é de agora, e «há 0 dias» não responde a isso.
    final quando = switch (dias) {
      <= 0 => 'colhido hoje às $h:$min',
      1 => 'colhido ontem às $h:$min',
      _ =>
        'colhido a ${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')} · há $dias dias',
    };
    return '$quantos personagens · $quando';
  }
}

/// A banda das três figuras, de margem a margem.
class _Banda extends StatelessWidget {
  const _Banda({
    required this.figuras,
    required this.wide,
    required this.larguraDaColuna,
    required this.onAbrir,
  });

  final List<FiguraViva> figuras;
  final bool wide;
  final double larguraDaColuna;
  final void Function(SearchQuery) onAbrir;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: PWColors.surface,
      border: Border(
        top: BorderSide(color: PWColors.border),
        bottom: BorderSide(color: PWColors.border),
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraDaColuna),
        child: wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < figuras.length; i++)
                      Expanded(
                        child: _Figura(
                          figura: figuras[i],
                          wide: true,
                          // **A primeira pulsa**, e é a que responde à
                          // pergunta *mudou alguma coisa desde ontem*.
                          pulsa: i == 0,
                          comFilete: i > 0,
                          onAbrir: () => onAbrir(figuras[i].query),
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < figuras.length; i++)
                    _Figura(
                      figura: figuras[i],
                      wide: false,
                      pulsa: i == 0,
                      comFileteEmCima: i > 0,
                      onAbrir: () => onAbrir(figuras[i].query),
                    ),
                ],
              ),
      ),
    ),
  );
}

class _Figura extends StatefulWidget {
  const _Figura({
    required this.figura,
    required this.wide,
    required this.pulsa,
    required this.onAbrir,
    this.comFilete = false,
    this.comFileteEmCima = false,
  });

  final FiguraViva figura;
  final bool wide;
  final bool pulsa;
  final VoidCallback onAbrir;
  final bool comFilete;
  final bool comFileteEmCima;

  @override
  State<_Figura> createState() => _FiguraState();
}

class _FiguraState extends State<_Figura> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _sobre = true),
    onExit: (_) => setState(() => _sobre = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onAbrir,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _sobre
              ? PWColors.accent.withValues(alpha: Maquete.versaoSobOPonteiro)
              : Colors.transparent,
          border: Border(
            left: widget.comFilete
                ? const BorderSide(color: PWColors.border)
                : BorderSide.none,
            top: widget.comFileteEmCima
                ? const BorderSide(color: PWColors.border)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              // `.vb { padding: 30px 10px 32px }`.
              padding: EdgeInsets.fromLTRB(
                10,
                widget.wide ? 30 : 22,
                10,
                widget.wide ? 32 : 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    groupThousands(widget.figura.numero),
                    style: TextStyle(
                      color: PWColors.text,
                      fontSize: widget.wide ? 38 : 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    widget.figura.rotulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // `.vb .r b { color: texto; font-weight: 500 }` — na
                      // maquete o rótulo inteiro está dentro do `<b>`.
                      color: PWColors.text,
                      fontSize: widget.wide ? 13 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(child: _Marcador(pulsa: widget.pulsa)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// O ponto sobre o filete.
///
/// **A maquete fá-lo pulsar na primeira figura e aqui ele está quieto**, e a
/// razão é o preço: uma `AnimationController.repeat()` agenda frames para
/// sempre, portanto `pumpAndSettle` deixa de terminar em **qualquer** teste
/// que monte esta página. Foram trinta e seis de uma vez, incluindo os da
/// raiz e os do filtro — este repositório tem mil e duzentos testes a contar
/// com ela.
///
/// O carrossel dos streamers tem uma animação infinita e não causa isto
/// porque só roda quando há mais canais do que cabem, o que é falso na
/// maioria dos testes. Aqui correria sempre.
///
/// Fica dito em `docs/maquete/LEIA-ME.md` como diferença deliberada.
class _Marcador extends StatelessWidget {
  const _Marcador({required this.pulsa});

  /// Hoje decide só a cor da sombra parada. Fica no construtor porque a
  /// distinção — *esta é a figura que responde a «mudou alguma coisa»* —
  /// continua a ser verdade, e é por ela que o halo existe.
  final bool pulsa;

  @override
  Widget build(BuildContext context) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: PWColors.accent,
      border: Border.all(color: PWColors.accent),
      boxShadow: pulsa
          ? [
              BoxShadow(
                color: PWColors.accent.withValues(alpha: 0.35),
                spreadRadius: 4,
              ),
            ]
          : null,
    ),
  );
}
