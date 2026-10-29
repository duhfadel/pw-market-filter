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

  // **Toda imagem que uma página pede tem de existir.**
  //
  // A 29/10/2026 uma expressão regular que preenchia o nome do ficheiro da
  // arte atravessou registos e deu ao Ceifador a arte do Guerreiro. Esse
  // caso concreto deixou de ser possível — o nome passou a ser derivado do
  // slug — mas a forma geral continua: **o HTML aponta para um ficheiro e
  // ninguém verifica que ele está lá.** Um `src` partido não falha nada; só
  // desenha um ícone de imagem partida a quem visita.
  for (final f in paginas) {
    final html = f.readAsStringSync();
    final pasta = f.parent.path;

    test('${f.path} aponta só para imagens que existem', () {
      final fontes = RegExp(r'<img[^>]+src="([^"]+)"')
          .allMatches(html)
          .map((m) => m.group(1)!)
          // Absolutas resolvem a partir de `web/`, relativas a partir da
          // pasta da própria página; endereços externos não são nossos.
          // Endereços externos não são nossos; e um `src` com `\${…}` é
          // montado em JavaScript a partir do Supabase quando a página
          // corre — o brasão de cada guilda no mapa das guerras — portanto
          // não há ficheiro nenhum no repositório para conferir.
          .where((s) =>
              !s.startsWith('http') &&
              !s.startsWith('data:') &&
              !s.contains(r'${'));

      for (final src in fontes) {
        // **`/assets/assets/…` é o caminho do build, não o do repositório.**
        // O Flutter copia a pasta `assets/` para dentro de `assets/` no
        // bundle, e é por isso que o logótipo de todas as páginas aparece
        // com o nome duplicado. No disco ele está em `assets/images/`.
        final caminho = src.startsWith('/assets/assets/')
            ? src.substring('/assets/'.length)
            : src.startsWith('/')
                ? 'web$src'
                : '$pasta/$src';
        expect(
          File(caminho).existsSync(),
          isTrue,
          reason: '${f.path} pede «$src», que não existe em $caminho.',
        );
      }
    });
  }

  // **Marcellus so estraga o `0` e o `1`, e isso foi medido.**
  //
  // Renderizando `0123456789` com o ficheiro real sai `OI23456789`: o zero e
  // um `O` e o um e um `I`. Os outros oito desenham normalmente. Por isso a
  // regra olha para `[01]` e nao para qualquer digito — a primeira versao
  // deste teste era severa demais e acusou *Os 52 territorios*, que esta
  // correcto.
  //
  // O defeito ja apareceu tres vezes — no guia das runas, no indice dos guias
  // e no do astrolabio — sempre apanhado a olhar para a pagina, nunca por um
  // teste. A folha tem `.algarismos`, que devolve o numero a pilha do
  // sistema, e e isso que este teste exige.
  //
  // Corre em todas as paginas que carregam `estilo.css`, que inclui as de
  // `/guerras/`: elas usam a folha dos guias para a casca.
  for (final f in paginas) {
    final html = f.readAsStringSync();
    if (!html.contains('guias/estilo.css') && !html.contains('"estilo.css"')) {
      continue;
    }

    test('${f.path} nao deixa digito solto num titulo', () {
      final titulos = RegExp(
        r'<h[123]>(.*?)</h[123]>',
        dotAll: true,
      ).allMatches(html);

      for (final t in titulos) {
        // Tira o que ja esta protegido antes de procurar digitos.
        final semProtegidos = t
            .group(1)!
            .replaceAll(
              RegExp(r'<span class="algarismos">.*?</span>', dotAll: true),
              '',
            );
        expect(
          semProtegidos.contains(RegExp(r'[01]')),
          isFalse,
          reason:
              'O titulo «${t.group(1)!.trim()}» tem um 0 ou um 1 fora de '
              '<span class="algarismos">: Marcellus desenha-os como O e I.',
        );
      }
    });
  }
}
