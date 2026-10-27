@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O que toda página HTML deste site tem de carregar.
///
/// **Existe porque uma página nova nasceu sem a tag do AdSense e ninguém
/// reparou.** A tag entrou a 22/10/2026 nas sete páginas que existiam; o guia
/// das Cartas Nuema nasceu a 23/10 e ficou de fora. Era a página mais recente
/// e a melhor do site, e era a única que o revisor não conseguia associar à
/// conta — descoberto cinco dias depois, a olhar à mão, página a página.
///
/// É a mesma forma que já custou caro aqui três vezes: **um campo novo não
/// está feito quando o parser o lê, está feito quando um teste o vê do outro
/// lado.** Aqui o "outro lado" é o ficheiro servido.
///
/// Varre `web/` em vez de listar as páginas, de propósito. Uma lista à mão
/// tem exactamente o mesmo defeito que este teste existe para apanhar: fica
/// desactualizada no dia em que alguém acrescenta uma página e não se lembra
/// de a inscrever aqui.
void main() {
  final paginas = Directory('web')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.html'))
      .toList();

  test('há páginas HTML para verificar', () {
    // Um `forEach` sobre uma lista vazia passa em silêncio, e aí este
    // ficheiro inteiro passaria a não testar nada sem nunca ficar vermelho.
    expect(paginas.length, greaterThanOrEqualTo(7));
  });

  for (final f in paginas) {
    final html = f.readAsStringSync();

    test('${f.path} carrega a tag do AdSense', () {
      // O número de editor e não só o nome do script: um `adsbygoogle.js` com
      // o id de outra conta verifica a conta de outra pessoa.
      expect(
        html,
        contains('ca-pub-7064703455080324'),
        reason:
            'Sem a tag, esta página não se associa à conta do AdSense. '
            'Copie o bloco `<!-- AdSense. ... -->` de outra página do site.',
      );
    });

    test('${f.path} liga a política de privacidade', () {
      // A política é obrigatória para o AdSense e pedida pela LGPD, e de nada
      // serve se a página que a precisa não lhe apontar. A própria política
      // está isenta: ela não se liga a si mesma.
      if (f.path.contains('privacidade')) return;
      expect(
        html,
        contains('/privacidade/'),
        reason: 'O rodapé desta página tem de ligar /privacidade/.',
      );
    });
  }
}
