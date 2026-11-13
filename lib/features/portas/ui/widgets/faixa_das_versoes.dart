import 'package:flutter/material.dart';

import '../../../../core/theme/medidas_da_maquete.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../../market/versoes.dart';
import '../../../home/domain/visit_label.dart' show groupThousands;
import '../../domain/versao.dart';

/// As três versões, lado a lado, sem arte.
///
/// **Escrita a partir do CSS da maquete e não a olho**, que é a lição que o
/// herói custou três voltas a aprender:
///
/// ```css
/// .viva { border-top:1px solid filete; border-bottom:1px solid filete;
///         background: #13132A }
/// .vz   { padding:34px 18px 36px; text-align:center }
/// .vz+.vz { border-left:1px solid filete }
/// .vz:hover { background: rgba(255,180,84,.045) }
/// .vz .v  { font-family: Marcellus; font-size:30px; letter-spacing:.04em }
/// .vz .n  { font-size:21px; font-weight:600; margin-top:12px }
/// .vz .un { font-size:12.5px; color:apagado; margin-top:3px }
/// .vz .ex { font-size:11.5px; color:ouro; margin-top:9px }
/// .vz .qd { font-size:10.5px; color:#5E5A7C; margin-top:7px }
/// .vz.breve { opacity:.62 }
/// ```
///
/// **Substituiu três retratos 2:3, e a arte perdeu-se de propósito.** Cada
/// porta vestia uma classe do seu elenco, e o raciocínio era bom enquanto
/// esta tela era só o garfo. Com o herói a abrir a página com um retrato a
/// toda a altura, três retratos logo abaixo punham **quatro** peças de arte
/// de classe no mesmo ecrã.
///
/// **Filete entre colunas e não moldura à volta de cada.** Três cartas com
/// borda lêem-se como três coisas a competir; três colunas de uma faixa
/// lêem-se como uma comparação, que é o que são.
class FaixaDasVersoes extends StatelessWidget {
  const FaixaDasVersoes({
    required this.portas,
    required this.wide,
    required this.larguraDaColuna,
    super.key,
  });

  final List<Porta> portas;
  final bool wide;

  /// A coluna de leitura da página. A faixa sangra de margem a margem — é
  /// esse o `border-top`/`border-bottom` da maquete a atravessar o ecrã — mas
  /// as três colunas alinham com o resto do conteúdo.
  final double larguraDaColuna;

  /// `background: var(--chao)`, que aqui se chama `surface`.
  static const _chao = PWColors.surface;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: _chao,
      border: Border(
        top: BorderSide(color: PWColors.border),
        bottom: BorderSide(color: PWColors.border),
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraDaColuna),
        child: wide ? _lado() : _empilhada(),
      ),
    ),
  );

  Widget _lado() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < portas.length; i++)
          Expanded(
            child: _Coluna(
              porta: portas[i],
              wide: true,
              // `.vz + .vz { border-left: 1px solid filete }` — o filete é da
              // coluna e não um widget entre elas, para a altura dele ser
              // exactamente a da coluna mais alta.
              comFileteAEsquerda: i > 0,
            ),
          ),
      ],
    ),
  );

  /// `.vz + .vz { border-left:0; border-top:1px solid filete }` no estreito.
  Widget _empilhada() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < portas.length; i++)
        _Coluna(porta: portas[i], wide: false, comFileteEmCima: i > 0),
    ],
  );
}

class _Coluna extends StatefulWidget {
  const _Coluna({
    required this.porta,
    required this.wide,
    this.comFileteAEsquerda = false,
    this.comFileteEmCima = false,
  });

  final Porta porta;
  final bool wide;
  final bool comFileteAEsquerda;
  final bool comFileteEmCima;

  @override
  State<_Coluna> createState() => _ColunaState();
}

class _ColunaState extends State<_Coluna> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final porta = widget.porta;
    final pronta = porta.pronta;
    final resumo = porta.resumo;

    return Opacity(
      key: Key('porta-${porta.chave}'),
      // `.vz.breve { opacity:.62 }`.
      opacity: pronta ? 1 : Maquete.versaoFechadaOpacidade,
      child: MouseRegion(
        onEnter: (_) => setState(() => _sobre = true),
        onExit: (_) => setState(() => _sobre = false),
        cursor: pronta ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: pronta
              ? () => Navigator.of(context).pushNamed(porta.rota!)
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // `.vz:hover { background: rgba(255,180,84,.045) }`.
              color: _sobre && pronta
                  ? PWColors.accent.withValues(
                      alpha: Maquete.versaoSobOPonteiro,
                    )
                  : Colors.transparent,
              border: Border(
                left: widget.comFileteAEsquerda
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
                  // `.vz { padding: 34px 18px 36px }`.
                  padding: const EdgeInsets.fromLTRB(18, 34, 18, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // **Centrada na vertical, e isso e nosso e nao da
                    // maquete.** La as tres colunas tem o mesmo numero de
                    // linhas; aqui as abertas levam mais uma -- a descricao
                    // do servidor que o dono pediu -- portanto a fechada
                    // ficava encostada ao topo a parecer cortada. Centrada,
                    // ela le-se como uma coluna mais curta em vez de uma
                    // coluna por acabar.
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // **Marcellus no rótulo da versão, e é a maquete a
                      // mandar.** A regra deste projecto é que nenhum número
                      // use a face de display — `150 TCC` sairia `I5O`. Um
                      // rótulo de versão é outro caso: três glifos com pontos
                      // a separá-los, a 30 px, e o `1` da Marcellus tem
                      // serifa em cima e base inteira. Conferido ampliando a
                      // maquete antes de copiar.
                      //
                      // Os **números** continuam na face do corpo, e a
                      // maquete concorda: `.num { font-family: var(--corpo) }`.
                      Text(
                        porta.nome,
                        style: const TextStyle(
                          fontFamily: PWTheme.display,
                          fontSize: 30,
                          letterSpacing: 1.2,
                          height: 1,
                          color: PWColors.text,
                        ),
                      ),
                      if (resumo != null && pronta)
                        _Numeros(resumo: resumo)
                      else
                        _Fechada(porta: porta),
                      // **A unica coisa que fica diferente da maquete, e e
                      // pedido do dono de 28/10/2026**: ali uma coluna com
                      // mercado mostra so numeros, e ele pediu a frase
                      // porque *«a tela pergunta qual mercado e so respondia
                      // com numeros»*. Quantos personagens ha e quando foi a
                      // coleta dizem o tamanho da loja; nao dizem nada sobre
                      // o jogo que esta la dentro, que e a unica coisa que um
                      // visitante novo precisa para decidir.
                      //
                      // Nas fechadas ela ja e a linha grande, portanto so se
                      // repete aqui.
                      if (resumo != null && pronta) ...[
                        const SizedBox(height: 10),
                        Text(
                          porta.descricao,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PWColors.apagado,
                            height: 1.45,
                          ),
                        ),
                      ],
                      // `.seta { opacity:0 }` → `.vz:hover .seta { opacity:1 }`
                      if (pronta)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _sobre ? 1 : 0,
                          child: const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'entrar →',
                              style: TextStyle(
                                fontSize: 12,
                                color: PWColors.accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // `.marcador { position:absolute; top:-6px; left:50% }` — o
                // ponto senta-se **em cima do filete** da faixa, metade de
                // cada lado. É o que o liga à linha em vez de o deixar a
                // flutuar dentro da coluna.
                Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(child: _Marcador(acesa: pronta)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O ponto de 11 px sobre o filete: cheio quando há mercado, vazado quando
/// ainda não.
class _Marcador extends StatelessWidget {
  const _Marcador({required this.acesa});

  final bool acesa;

  @override
  Widget build(BuildContext context) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      // `background: var(--noite)` quando vazado — o fundo da página, para o
      // filete não passar por dentro do ponto.
      color: acesa ? PWColors.accent : PWColors.background,
      border: Border.all(color: PWColors.accent),
    ),
  );
}

class _Numeros extends StatelessWidget {
  const _Numeros({required this.resumo});

  final VersaoResumo resumo;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // `.n { font-size:21px; font-weight:600; margin-top:12px }`
      const SizedBox(height: 12),
      Text(
        groupThousands(resumo.personagens),
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: PWColors.text,
          height: 1.1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        'personagens à venda',
        style: TextStyle(fontSize: 12.5, color: PWColors.apagado),
      ),
      // Ausente não desenha linha; zero desenha. Ver `VersaoResumo.novosHoje`.
      if (resumo.novosHoje != null) ...[
        const SizedBox(height: 9),
        Text(
          _novos(resumo.novosHoje!),
          style: const TextStyle(
            fontSize: 11.5,
            color: PWColors.accent,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
      const SizedBox(height: 7),
      Text(
        'colhido em ${_data(resumo.coletadoEm.toLocal())}',
        // `.qd { color:#5E5A7C }` — mais apagado do que `apagado`, porque a
        // data é contexto e não um dos números que se comparam.
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF5E5A7C)),
      ),
    ],
  );

  /// Singular e plural à mão: `1 entraram` lê-se como avaria, e com um
  /// mercado a crescer 17% em duas semanas o dia de um só anúncio existe.
  static String _novos(int quantos) => switch (quantos) {
    0 => 'ninguém novo hoje',
    1 => '1 entrou hoje',
    _ => '${groupThousands(quantos)} entraram hoje',
  };

  static String _data(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}';
  }
}

/// A coluna de uma versão que ainda não abriu.
///
/// `.vz.breve .n { font-size:16px; color:apagado; font-weight:500 }` — a
/// linha grande passa a ser a data de abertura, e a descrição vem abaixo.
class _Fechada extends StatelessWidget {
  const _Fechada({required this.porta});

  final Porta porta;

  @override
  Widget build(BuildContext context) {
    final (abertura, resto) = _partir(porta.descricao);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(
          abertura,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: PWColors.apagado,
            height: 1.25,
          ),
        ),
        if (resto != null) ...[
          const SizedBox(height: 4),
          Text(
            resto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: PWColors.apagado,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// A descrição do dono é uma frase só — *«Abre a 13 de novembro de 2026.
  /// Cinco raças, dez classes…»* — e a maquete mostra-a em duas linhas de
  /// pesos diferentes. Parte-se na primeira frase, que é onde ele já a tinha
  /// partido ao escrevê-la.
  static (String, String?) _partir(String descricao) {
    final ponto = descricao.indexOf('. ');
    if (ponto < 0) return (descricao, null);
    return (descricao.substring(0, ponto), descricao.substring(ponto + 2));
  }
}
