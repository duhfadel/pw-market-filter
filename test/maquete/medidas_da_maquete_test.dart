import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/medidas_da_maquete.dart';
import 'package:pw_market_filter/features/home/ui/widgets/palco_de_classe.dart';
import 'package:pw_market_filter/features/portas/ui/widgets/heroi_da_raiz.dart';

/// Lê o CSS da maquete e compara-o com o que o código diz.
///
/// **Pedido do dono a 09/11/2026**, nos termos dele: *«coloca na spec pra
/// ficar revisando a maquete até que o código fique igual»*. Uma nota numa
/// spec depende de alguém se lembrar de a reler; isto falha sozinho.
///
/// **A maquete está versionada em `docs/maquete/home.html`** — estava numa
/// pasta temporária da sessão até este commit, o que quer dizer que a
/// referência do redesenho podia desaparecer sem ninguém dar por isso.
///
/// Não compara píxeis e não abre navegador nenhum: compara **números**. O que
/// custou três voltas no herói não foi a renderização estar errada, foi eu
/// ter deduzido valores que o CSS declarava.
void main() {
  final ficheiro = File('docs/maquete/home.html');
  late String css;

  setUpAll(() {
    expect(
      ficheiro.existsSync(),
      isTrue,
      reason:
          'a maquete é a referência do redesenho e tem de estar no '
          'repositório — ver docs/maquete/LEIA-ME.md',
    );
    css = ficheiro.readAsStringSync();
  });

  /// O primeiro número que casa com [padrao] dentro da regra de [seletor].
  List<double> numerosDe(String seletor, String padrao) {
    final regra = RegExp(
      '${RegExp.escape(seletor)}[^{]*\\{([^}]*)\\}',
    ).firstMatch(css);
    expect(regra, isNotNull, reason: 'a maquete já não tem a regra $seletor');
    final m = RegExp(padrao).firstMatch(regra!.group(1)!);
    expect(
      m,
      isNotNull,
      reason:
          'a regra $seletor já não casa com $padrao — a maquete mudou, e '
          'o código tem de a seguir ou a diferença tem de ser escrita em '
          'docs/maquete/LEIA-ME.md',
    );
    return [for (var i = 1; i <= m!.groupCount; i++) double.parse(m.group(i)!)];
  }

  test('a coluna de leitura', () {
    final m = RegExp(r'--col:\s*(\d+)px').firstMatch(css);
    expect(double.parse(m!.group(1)!), Maquete.colunaDeLeitura);
  });

  test('a altura do herói', () {
    // `min-height: min(86vh, 760px)`
    final v = numerosDe('.heroi', r'min\((\d+)vh,\s*(\d+)px\)');
    expect(v[0] / 100, Maquete.heroiFraccaoDaJanela);
    expect(v[1], Maquete.heroiAlturaMaxima);

    // E a função que a desenha usa mesmo estes números.
    expect(HeroiDaRaiz.alturaPara(true, 1000), 860.0.clamp(420, 760));
    expect(HeroiDaRaiz.alturaPara(true, 800), closeTo(688, 0.5));
    expect(HeroiDaRaiz.alturaPara(true, 2000), Maquete.heroiAlturaMaxima);
  });

  test('o enquadramento da arte', () {
    // `object-position: 76% 20%`
    final v = numerosDe('.arteheroi', r'object-position:\s*(\d+)%\s+(\d+)%');
    expect(v[0] / 100, Maquete.arteDoHeroiX);
    expect(v[1] / 100, Maquete.arteDoHeroiY);
    expect(EnquadramentoDaArte.heroi.alinhamento, Maquete.alinhamentoDaArte);
    expect(
      Maquete.alinhamentoDaArte,
      const Alignment(0.52, -0.6),
      reason: 'a conversão de `object-position` é 2 × fracção − 1',
    );
  });

  test('a arte cobre, nunca encaixa', () {
    final regra = RegExp(r'\.arteheroi[^{]*\{([^}]*)\}').firstMatch(css)!;
    expect(
      regra.group(1),
      contains('object-fit:cover'),
      reason:
          'o painel encostado à direita foi uma dedução minha e estava '
          'errado: a maquete sempre cobriu a largura toda',
    );
  });

  test('a escala da manchete', () {
    // `font-size: clamp(38px, 5.6vw, 68px)`
    final v = numerosDe(
      '.heroi h1',
      r'clamp\((\d+)px,\s*([\d.]+)vw,\s*(\d+)px\)',
    );
    expect(v[0], Maquete.mancheteMinima);
    expect(v[1] / 100, closeTo(Maquete.mancheteFraccao, 1e-9));
    expect(v[2], Maquete.mancheteMaxima);
  });

  test('a pílula é translúcida, com desfoque', () {
    // Reparado pelo dono: «as pílulas não deveriam ter opacidade?».
    final regra = RegExp(r'\.pil\{([^}]*)\}').firstMatch(css)!.group(1)!;
    final fundo = RegExp(
      r'background:rgba\(11,11,26,([\d.]+)\)',
    ).firstMatch(regra);
    expect(fundo, isNotNull, reason: 'a pílula deixou de ser translúcida');
    expect(double.parse(fundo!.group(1)!), Maquete.pilulaOpacidade);

    final desfoque = RegExp(
      r'backdrop-filter:blur\((\d+)px\)',
    ).firstMatch(regra);
    expect(double.parse(desfoque!.group(1)!), Maquete.pilulaDesfoque);

    final borda = RegExp(
      r'border:1px solid rgba\(255,255,255,([\d.]+)\)',
    ).firstMatch(regra);
    expect(double.parse(borda!.group(1)!), Maquete.pilulaBorda);
  });

  test('a pílula de Novidades é a de ouro', () {
    final regra = RegExp(r'\.pil\.ouro\{([^}]*)\}').firstMatch(css)!.group(1)!;
    final m = RegExp(r'rgba\(255,180,84,([\d.]+)\)').firstMatch(regra);
    expect(double.parse(m!.group(1)!), Maquete.pilulaBordaOuro);
  });

  test('o respiro de secção', () {
    final m = RegExp(r'section\{padding:(\d+)px 0\}').firstMatch(css);
    expect(double.parse(m!.group(1)!), Maquete.respiroDeSeccao);
  });

  test('a versão fechada e a que está sob o ponteiro', () {
    final fechada = RegExp(r'\.vz\.breve\{opacity:\.?(\d+)\}').firstMatch(css);
    expect(
      double.parse('0.${fechada!.group(1)}'),
      Maquete.versaoFechadaOpacidade,
    );

    final sobre = RegExp(
      r'\.vz:hover\{background:rgba\(255,180,84,([\d.]+)\)',
    ).firstMatch(css);
    expect(double.parse(sobre!.group(1)!), Maquete.versaoSobOPonteiro);
  });

  test('a arte da maquete é a mesma do site, e não uma cópia', () {
    // Duas cópias divergem na primeira vez que alguém trocar um ficheiro.
    expect(css, contains('classes-verticais/960/'));
    expect(
      Directory('assets/images/classes-verticais/960').existsSync(),
      isTrue,
    );
  });
}
