import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/market_index.dart';
import '../../../search/domain/search_query.dart';
import '../../domain/faixa_viva.dart';

/// O mercado agora: três números, cada um uma porta para o filtro com a
/// pergunta já feita.
///
/// **É a única coisa na página que muda sozinha todos os dias**, e é a
/// resposta ao *não convida a voltar*. `firstSeen` e `previousPrice` são
/// recolhidos desde 30/09/2026 e nunca tinham aparecido em tela nenhuma — a
/// forma de desperdício que este repositório já conhece pelo nome, depois do
/// `sexo` colhido em Agosto e mostrado em Outubro.
///
/// **O carimbo da coleta vem com os números e não à parte.** Um índice velho
/// parece exactamente igual a um fresco, e um filtro perfeito sobre dados do
/// mês passado é pior do que filtro nenhum, porque lê como certo. Passada uma
/// semana a data acende, que é a regra que a tela do filtro já segue.
///
/// **Nenhum número usa a Marcellus.** Ela desenha algarismos romanos — `150`
/// sai `I5O` — e isto é uma faixa feita só de números.
class FaixaViva extends StatelessWidget {
  const FaixaViva({
    required this.index,
    required this.wide,
    required this.onAbrir,
    super.key,
  });

  final MarketIndex index;
  final bool wide;

  /// Abre o filtro já a responder à pergunta da figura tocada.
  final void Function(SearchQuery) onAbrir;

  /// Passada uma semana o carimbo acende. O mesmo limite que a tela do filtro
  /// usa — um só número, lido de um só lugar, para as duas telas não poderem
  /// discordar sobre o que é velho.
  static const diasAteEnvelhecer = 7;

  @override
  Widget build(BuildContext context) {
    final figuras = figurasVivas(index);
    final agora = DateTime.now();
    // Um só número para a cor e para as palavras. Lidos de sítios
    // diferentes, discordariam na fronteira — seis dias decorridos podem ser
    // sete de calendário — e a faixa acenderia a dizer «há 6 dias».
    final dias = diasDeCalendario(index.collectedAt, agora);
    final velho = dias >= diasAteEnvelhecer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < figuras.length; i++) ...[
              if (i > 0) SizedBox(width: wide ? 10 : 6),
              Expanded(
                child: _Figura(
                  figura: figuras[i],
                  wide: wide,
                  onAbrir: () => onAbrir(figuras[i].query),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: wide ? 8 : 6),
        Text(
          _carimbo(index.collectedAt, dias),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: velho ? PWColors.accent : PWColors.textMuted,
            fontSize: wide ? 11 : 10,
          ),
        ),
      ],
    );
  }

  /// **«Hoje» é o dia do calendário e não vinte e quatro horas**, e a
  /// diferença morde: a coleta corre a cada meia hora, portanto um índice de
  /// ontem às 23:50 lido à 00:10 tem *zero* dias decorridos e não é de hoje.
  /// Dizer-lhe «hoje» é a tela a afirmar frescura que não tem — o defeito
  /// exacto que o carimbo existe para evitar.
  static int diasDeCalendario(DateTime quando, DateTime agora) => DateTime(
    agora.year,
    agora.month,
    agora.day,
  ).difference(DateTime(quando.year, quando.month, quando.day)).inDays;

  static String _carimbo(DateTime quando, int dias) {
    final d = quando.day.toString().padLeft(2, '0');
    final m = quando.month.toString().padLeft(2, '0');
    final h = quando.hour.toString().padLeft(2, '0');
    final min = quando.minute.toString().padLeft(2, '0');
    // Dentro do dia a hora diz mais do que a data: quem volta ao site quer
    // saber se isto é de agora, e «há 0 dias» não responde a isso.
    if (dias <= 0) return 'coletado hoje às $h:$min';
    if (dias == 1) return 'coletado ontem às $h:$min';
    return 'coletado a $d/$m às $h:$min · há $dias dias';
  }
}

/// Uma figura: o número, o que ele conta, e o toque que abre a grelha.
///
/// **O número inteiro cabe sempre.** É ele que a faixa existe para dizer, e
/// `FittedBox` encolhe-o em vez de o cortar — a mesma regra que põe o `+70`
/// preso à direita no cartão: o número nunca é a parte que se perde.
class _Figura extends StatelessWidget {
  const _Figura({
    required this.figura,
    required this.wide,
    required this.onAbrir,
  });

  final FiguraViva figura;
  final bool wide;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) => Material(
    color: PWColors.surface,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onAbrir,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 14 : 8,
          vertical: wide ? 12 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PWColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _comPontos(figura.numero),
                style: TextStyle(
                  color: PWColors.text,
                  fontSize: wide ? 28 : 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(height: wide ? 2 : 1),
            Text(
              figura.rotulo,
              style: TextStyle(
                color: PWColors.textMuted,
                fontSize: wide ? 12 : 10,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// `2953` lido de relance é quatro dígitos sem forma; `2.953` é um número.
  static String _comPontos(int n) {
    final digitos = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) out.write('.');
      out.write(digitos[i]);
    }
    return out.toString();
  }
}
