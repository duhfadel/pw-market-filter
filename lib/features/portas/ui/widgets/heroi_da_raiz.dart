import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../home/domain/arte_da_classe.dart';
import '../../../home/ui/widgets/palco_de_classe.dart';

/// O herói da raiz: a arte de uma classe a sangrar, com o que o site faz
/// escrito no espaço vazio dela.
///
/// **A arte é o chão e não uma ilustração ao lado do conteúdo** — o mesmo
/// dispositivo do `Cartaz`, partilhado por `PalcoDeClasse` em vez de copiado.
///
/// **A classe sai das seis clássicas, e isso resolve uma pergunta que a spec
/// deixou aberta**: *«a arte do herói na raiz é de uma classe de 1.8.7, numa
/// página que serve as três versões»*. As seis de [classesClassicasPw126]
/// existem nas três, portanto nenhuma delas promete um mercado em que não se
/// pode entrar. Uma das onze que só o 1.8.7 tem diria, em arte, que esta é a
/// página do 1.8.7.
///
/// **Muda a cada coleta e nunca a cada build.** Deriva de uma data, como
/// `classeDoCartaz` faz: a mesma coleta tem de desenhar a mesma página, ou um
/// recarregamento lê como caça-níqueis em vez de site.
class HeroiDaRaiz extends StatelessWidget {
  const HeroiDaRaiz({
    required this.wide,
    required this.quando,
    this.margemHorizontal = 24,
    super.key,
  });

  final bool wide;

  /// A data da coleta mais recente — o relógio que escolhe a classe.
  final DateTime quando;

  final double margemHorizontal;

  /// **Mais alto do que o `Cartaz`, e a diferença é o que está por baixo.**
  /// O Cartaz tem os Destaques a disputar a dobra logo a seguir; aqui a
  /// primeira coisa abaixo é a prosa, que pode esperar.
  ///
  /// **Inclui a altura da barra**, que assenta por cima: o palco começa no
  /// topo do ecrã, portanto os ~56 px da barra saem do que sobra para o
  /// texto e têm de ser devolvidos aqui.
  ///
  /// **750 no largo é a medida da maquete**, e é alta de propósito: a esta
  /// altura o herói ocupa a dobra quase inteira num ecrã de 1000, que é o
  /// que o torna um herói em vez de uma faixa. O preço é a premissa começar
  /// abaixo da dobra — aceite, porque quem rola uma vez encontra-a e quem
  /// não rola já leu a manchete, que diz a mesma coisa em sete palavras.
  static double alturaPara(bool wide) => wide ? 750 : 470;

  /// A classe que o herói veste — **o Guerreiro, sempre**.
  ///
  /// **Era rotativa e deixou de ser, por decisão do dono.** A primeira versão
  /// trocava de classe a cada coleta, como o `Cartaz` faz nas telas de
  /// versão, e o argumento era bom: duas visitas não abrem a mesma página. O
  /// dono pôs a maquete ao lado do que estava no ar e disse *«usa a mesma
  /// imagem»* — e tem razão por uma razão que o argumento antigo não pesava.
  ///
  /// **A porta da frente não ganha nada em mudar de cara.** O `Cartaz` roda
  /// dentro de um mercado, para quem já entrou; aqui é o primeiro ecrã de
  /// quem nunca viu o site, e a arte é metade do que ele vai lembrar. Cinco
  /// das seis classes dariam uma dobra diferente da que foi desenhada e
  /// aprovada, e a arte fria do Arqueiro — que foi a que calhou ao comparar —
  /// dá uma página visivelmente mais pobre do que a quente do Guerreiro.
  ///
  /// [classeDe] fica, e é o que a mantém rotativa a um parâmetro de
  /// distância se isto se revelar errado.
  static const classeDoHeroi = 'Guerreiro';

  /// A classe que uma coleta escolheria, se o herói voltasse a rodar.
  static String classeDe(DateTime quando) {
    final dia = DateTime.utc(quando.year, quando.month, quando.day);
    final passo = quando.hour ~/ 6;
    final n = dia.difference(DateTime.utc(2026, 1, 1)).inDays * 4 + passo;
    return classesClassicasPw126[n % classesClassicasPw126.length];
  }

  @override
  Widget build(BuildContext context) => PalcoDeClasse(
    classe: classeDoHeroi,
    altura: alturaPara(wide),
    margemHorizontal: margemHorizontal,
    // **Encostada só no largo.** A 390 px o painel 2:3 ocupa quase a largura
    // toda, portanto a manchete e a prosa caíam em cima da figura — visto a
    // renderizar, não deduzido. No estreito volta ao enquadramento que o
    // `Cartaz` já prova a 340 px: arte a cobrir a caixa, com as duas lavagens
    // a segurar a legibilidade.
    arteADireita: wide,
    child: _Texto(wide: wide),
  );
}

class _Texto extends StatelessWidget {
  const _Texto({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // A manchete e a sub-linha param antes da figura começar. Sem tecto, a
    // linha corria por cima da cara da arte numa janela larga.
    constraints: BoxConstraints(maxWidth: wide ? 540 : 420),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FERRAMENTAS E GUIAS · THE CLASSIC PW',
          style: TextStyle(
            color: PWColors.apagado,
            fontSize: wide ? 12 : 10.5,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: wide ? 16 : 12),
        // Sem algarismos, portanto a face de display é segura aqui — a
        // Marcellus desenha figuras romanas e o seu `1` não tem bandeira.
        Text(
          'As contas que o jogo não faz',
          style: TextStyle(
            fontFamily: PWTheme.display,
            fontSize: wide ? 60 : 36,
            color: PWColors.papel,
            height: 1.08,
          ),
        ),
        SizedBox(height: wide ? 16 : 12),
        Text(
          'Filtre o mercado pelo que cada personagem está usando, veja '
          'quanto custa uma runa nível 10 e siga as missões da Saga do '
          'Herói.',
          style: TextStyle(
            color: PWColors.apagado,
            fontSize: wide ? 15 : 13.5,
            height: 1.55,
          ),
        ),
        SizedBox(height: wide ? 24 : 18),
        const _Botao(),
      ],
    ),
  );
}

/// Uma porta só, e para os guias.
///
/// **Não é «ver o mercado»**: a pergunta *qual mercado* é a que as portas
/// logo abaixo existem para fazer, e um botão aqui respondê-la-ia em
/// silêncio — o defeito de 27/10/2026, quando o seletor oferecia pílulas que
/// escolhiam o 1.8.7 sem dizer. Os guias não têm esse problema: servem as
/// três.
class _Botao extends StatelessWidget {
  const _Botao();

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () =>
        unawaited(launchUrl(Uri.parse('/guias/'), webOnlyWindowName: '_self')),
    style: OutlinedButton.styleFrom(
      foregroundColor: PWColors.papel,
      side: const BorderSide(color: PWColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      backgroundColor: PWColors.surface.withValues(alpha: 0.55),
    ),
    child: const Text('Ver todos os guias'),
  );
}
