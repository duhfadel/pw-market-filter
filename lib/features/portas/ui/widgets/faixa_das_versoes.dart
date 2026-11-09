import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../home/domain/visit_label.dart' show groupThousands;
import '../../../../market/versoes.dart';
import '../../domain/versao.dart';

/// As três versões, lado a lado, sem arte.
///
/// **Substituiu três retratos 2:3 a 09/11/2026, e a arte perdeu-se de
/// propósito.** Cada porta vestia uma classe do seu próprio elenco, e o
/// raciocínio era bom enquanto esta tela era só o garfo. Deixou de ser: com o
/// herói a abrir a página com um retrato a toda a altura, três retratos logo
/// abaixo põem **quatro** peças de arte de classe no mesmo ecrã, e a que
/// manda deixa de mandar. A escolha é da maquete e o argumento é esse.
///
/// **O que fica no lugar é o que a tela existe para dizer**: qual mercado,
/// quantos há, quantos entraram hoje, e de quando é a leitura.
///
/// **O filete entre colunas e não uma moldura à volta de cada.** Três cartas
/// com borda lêem-se como três coisas separadas a competir; três colunas de
/// uma faixa lêem-se como uma comparação, que é o que são.
class FaixaDasVersoes extends StatelessWidget {
  const FaixaDasVersoes({required this.portas, required this.wide, super.key});

  final List<Porta> portas;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    // Empilhadas no telemóvel: três colunas a 390 px dariam 120 px cada, e o
    // número — que é o que a faixa existe para mostrar — teria de encolher
    // até deixar de se ler de relance.
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < portas.length; i++) ...[
            if (i > 0) const Divider(color: PWColors.border, height: 1),
            _Coluna(porta: portas[i], wide: false),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < portas.length; i++) ...[
            if (i > 0)
              const VerticalDivider(
                color: PWColors.border,
                width: 1,
                thickness: 1,
              ),
            Expanded(child: _Coluna(porta: portas[i], wide: true)),
          ],
        ],
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  const _Coluna({required this.porta, required this.wide});

  final Porta porta;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final pronta = porta.pronta;
    final resumo = porta.resumo;

    return Opacity(
      key: Key('porta-${porta.chave}'),
      // O mesmo 0.5 com que `GavetaItem` esmaece uma ferramenta por publicar
      // — uma regra para «a forma do lugar existe antes do lugar», desenhada
      // duas vezes.
      opacity: pronta ? 1 : 0.5,
      child: Material(
        // **`transparency` e não uma cor transparente.** Com o tipo por
        // omissão o `Material` continua a pintar um chão por baixo da
        // ondulação, e as duas colunas clicáveis saíam com uma caixa mais
        // clara que a terceira — três colunas de uma faixa a parecerem duas
        // cartas e um buraco. Só se viu renderizando.
        type: MaterialType.transparency,
        child: InkWell(
          // `null` e não um callback vazio: o próprio `InkWell` lê o nulo
          // como desactivado, que é o que impede uma porta fechada de
          // desenhar a sua ondulação sobre nada.
          onTap: pronta
              ? () => Navigator.of(context).pushNamed(porta.rota!)
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 20 : 16,
              vertical: wide ? 26 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Ponto(acesa: pronta),
                SizedBox(height: wide ? 14 : 10),
                // Marcellus num número seria `I.8.7` — ela desenha figuras
                // romanas. O nome da versão fica na face do corpo, como
                // todo o algarismo deste site.
                Text(
                  porta.nome,
                  style: TextStyle(
                    color: PWColors.papel,
                    fontSize: wide ? 30 : 26,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
                SizedBox(height: wide ? 14 : 10),
                if (resumo != null && pronta) ...[
                  _Numeros(resumo: resumo, wide: wide),
                  SizedBox(height: wide ? 12 : 10),
                ],
                // **A descrição fica nas três colunas, inclusive nas que já
                // têm números**, e isso é pedido do dono de 28/10/2026: *a
                // tela pergunta qual mercado e só respondia com números*.
                // Quantos personagens há e quando foi a coleta dizem o
                // tamanho da loja; não dizem nada sobre o jogo que está lá
                // dentro, que é a única coisa que um visitante novo precisa
                // para decidir. A maquete só a mostrava na versão fechada —
                // aqui o pedido dele ganha.
                _Descricao(porta: porta, wide: wide),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O ponto acima do nome: cheio quando há mercado, vazado quando ainda não.
///
/// **Um ponto e não um selo de texto.** O *em breve* dizia o mesmo e ocupava
/// uma linha inteira numa coluna que existe para mostrar números; aqui a
/// descrição logo abaixo já diz quando abre, portanto o selo repetia-a.
class _Ponto extends StatelessWidget {
  const _Ponto({required this.acesa});

  final bool acesa;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: acesa ? PWColors.accent : Colors.transparent,
      border: acesa ? null : Border.all(color: PWColors.textMuted),
    ),
  );
}

class _Numeros extends StatelessWidget {
  const _Numeros({required this.resumo, required this.wide});

  final VersaoResumo resumo;
  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        groupThousands(resumo.personagens),
        style: TextStyle(
          color: PWColors.text,
          fontSize: wide ? 24 : 21,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        'personagens à venda',
        style: TextStyle(color: PWColors.apagado, fontSize: wide ? 12.5 : 12),
      ),
      // Ausente não desenha linha; zero desenha. Ver `VersaoResumo.novosHoje`:
      // um ficheiro anterior ao campo não pode fazer a porta anunciar um
      // mercado parado.
      if (resumo.novosHoje != null) ...[
        const SizedBox(height: 7),
        Text(
          _novos(resumo.novosHoje!),
          style: TextStyle(color: PWColors.accent, fontSize: wide ? 13 : 12.5),
        ),
      ],
      const SizedBox(height: 7),
      Text(
        'coletado em ${_data(resumo.coletadoEm.toLocal())}',
        style: TextStyle(color: PWColors.apagado, fontSize: wide ? 11 : 10.5),
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
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }
}

/// A frase do dono sobre o servidor — o que o número não diz.
class _Descricao extends StatelessWidget {
  const _Descricao({required this.porta, required this.wide});

  final Porta porta;
  final bool wide;

  @override
  Widget build(BuildContext context) => Text(
    porta.descricao,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: PWColors.apagado,
      fontSize: wide ? 12.5 : 12,
      height: 1.45,
    ),
  );
}
