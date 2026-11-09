import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';

/// A abertura da raiz: o que o site faz, antes de dizer o nome dele.
///
/// **A raiz era um torniquete e deixou de ser, a 09/11/2026.** Eram três
/// cartas e **148 palavras** — e foi precisamente esta a página que o AdSense
/// viu como vazia a 31/10. A doc de `PortasView` dizia que a tela *«responde
/// duas perguntas e nada mais, de propósito»*, com o argumento de que não há
/// nada para vender a quem já está no site. O argumento vale para quem chegou
/// por um link de `/filtro` e já sabe o que isto é; não vale para quem
/// escreveu `portalpw.net` às cegas, que é exactamente quem esta tela recebe.
///
/// **A apresentação existe porque faltava a premissa**, e foi o dono a
/// apontá-la: «talvez falte a informaçao antes do market para que o pessoal
/// entenda o que sao aqueles numeros». Sem ela, *2.486 personagens à venda* é
/// um número sem substantivo.
class Abertura extends StatelessWidget {
  const Abertura({required this.wide, super.key});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // **A manchete saiu daqui a 09/11/2026**, no mesmo dia em que entrou:
      // o herói passou a dizê-la em Marcellus sobre a arte, e tê-la nos dois
      // sítios punha a mesma frase duas vezes na mesma dobra. Fica a secção,
      // que é outra pergunta — *o que é isto que vou ver números sobre*.
      Text(
        'Três versões, três mercados',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: wide ? 30 : 23,
          color: PWColors.papel,
          height: 1.15,
        ),
      ),
      SizedBox(height: wide ? 16 : 12),
      // **A primeira frase é centrada e as outras não**, e é o que a maquete
      // faz com o espaço: ali a secção abre com uma linha curta ao centro.
      // Centrar as quatro faria uma coluna com as duas margens irregulares —
      // bonito numa frase, ilegível num texto de doze linhas.
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'No The Classic dá para vender o personagem inteiro — com o '
            'equipamento, as cartas e tudo o que ele carrega. Cada versão '
            'tem o seu mercado, e é neles que este site procura.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PWColors.apagado,
              fontSize: wide ? 14.5 : 13.5,
              height: 1.6,
            ),
          ),
        ),
      ),
      SizedBox(height: wide ? 20 : 16),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _Premissa(wide: wide),
        ),
      ),
    ],
  );
}

/// O parágrafo que dá substantivo aos números das portas.
///
/// **Nenhum preço, e isso é uma regra e não um esquecimento.** Um número do
/// jogo é permanente e um preço de mercado não é — a lição que o guia das
/// runas deixou — portanto a prosa aqui carrega só factos do jogo e os
/// números que se movem ficam nas portas, onde a data da coleta está ao lado.
///
/// A primeira versão deste parágrafo dizia *«a de 70 vende por 1000 TCC e as
/// de 40 por 90»*, copiado de uma medição de Agosto sobre 770 personagens.
/// Medido outra vez a 09/11 sobre 2.486: o Dilacerador Raivoso, de 70, vai de
/// 40 a 2500 TCC e o do Vento, de 40, vai de 40 a 500 — **as faixas
/// sobrepõem-se**, e a frase antiga tinha deixado de ser verdade sem ninguém
/// notar. É exactamente por isso que ela saiu em vez de ser actualizada.
///
/// **E o 70 já não é o topo**, o que o dono tinha previsto: «cada vez mais, as
/// armas do 70 serao mais normais». A 09/11 são 1107 de 2486 pessoas, e acima
/// delas há 52 com 80. O parágrafo diz *a arma de topo de cada classe* sem
/// cravar o número, por isso.
///
/// O que fica é medido e durável: **quatro armas chamam-se Dilacerador** —
/// ★★Gelado dá 30, ★★★do Vento dá 40, ★★★Raivoso dá 70, e ★★★de Almas, com
/// as mesmas três estrelas, não dá nível de ataque nenhum.
class _Premissa extends StatelessWidget {
  const _Premissa({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // A frase de abertura mudou-se para a secção, centrada. O que fica
      // aqui é o que ela não diz: o site do jogo deixa procurar por nível,
      // classe e preço — e é o que **não** deixa que explica este site.
      Text(
        'O site do jogo lista quem está à venda e deixa procurar por nível, '
        'classe e preço. O que ele não deixa procurar é pelos atributos do '
        'que o personagem está usando — e é isso que decide se um anúncio '
        'vale o preço.',
        style: _corpo(wide),
      ),
      SizedBox(height: wide ? 10 : 8),
      Text(
        'Quatro armas do jogo chamam-se Dilacerador. Uma dá 30 de nível de '
        'ataque, outra 40, outra 70 — e a quarta, com as mesmas três '
        'estrelas das outras, não dá nenhum. Pelo nome são a mesma arma; '
        'pelo que fazem, não são nem parecidas.',
        style: _corpo(wide),
      ),
      SizedBox(height: wide ? 10 : 8),
      Text(
        'Cada uma das dezassete classes tem a sua arma de topo, com nome '
        'próprio, para o mesmo patamar. Procurar pelo atributo em vez do '
        'nome é o que este site faz e o do jogo não.',
        style: _corpo(wide),
      ),
    ],
  );

  static TextStyle _corpo(bool wide) => TextStyle(
    color: PWColors.apagado,
    fontSize: wide ? 14 : 13,
    height: 1.55,
  );
}
