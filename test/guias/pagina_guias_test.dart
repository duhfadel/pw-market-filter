import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/guia.dart';

import '../../tool/guias/pagina.dart';

/// Pins the generated list against the declaration.
///
/// A list that is generated but not regenerated is worse than a hand-written
/// one: it looks derived and is stale. This is the check that makes editing
/// `guias` without running the tool fail the suite.
void main() {
  final caminho = 'web/guias/index.html';
  late String emDisco;

  setUpAll(() => emDisco = File(caminho).readAsStringSync());

  test('a página em disco concorda com a declaração', () {
    expect(
      paginaCom(emDisco),
      emDisco,
      reason: 'corre `dart run tool/guias/pagina.dart`',
    );
  });

  test('nenhuma data é gravada no HTML gerado', () {
    // **O selo não pode ser desenhado pelo gerador.** Gravado, o ficheiro
    // passava a discordar da regeneração no dia em que o primeiro expirasse,
    // e o teste acima ficaria vermelho pelo calendário e não por defeito —
    // um gate de publicação cuja entrada é o mundo, que é a forma que já
    // congelou este site duas vezes.
    final lista = RegExp(
      r'<!-- INÍCIO DA LISTA -->(.*)<!-- FIM DA LISTA -->',
      dotAll: true,
    ).firstMatch(emDisco)!.group(1)!;
    expect(lista.contains('selo'), isFalse);
    expect(lista, contains('data-publicado='));
  });

  test('cada carta diz a que versão serve e quanto tempo leva', () {
    for (final guia in guias) {
      final carta = RegExp(
        '<a class="guia" href="${RegExp.escape(guia.endereco)}".*?</a>',
        dotAll: true,
      ).firstMatch(emDisco);
      expect(carta, isNotNull, reason: '«${guia.titulo}» não está na página');
      expect(carta!.group(0), contains('class="meta"'));
      expect(carta.group(0), contains('class="versao"'));
      expect(carta.group(0), contains('class="duracao"'));
    }
  });

  test('o guia da app aparece na lista como qualquer outro', () {
    // Ele é o único que não tem página em disco, e por isso é o único que
    // poderia cair fora por acidente.
    expect(emDisco, contains('href="/multicontas"'));
  });

  group('o tempo de leitura', () {
    test('é medido do ficheiro e cai numa faixa que alguém acredita', () {
      for (final guia in guias) {
        if (guia.medida != null) continue;
        final minutos = minutosDe(guia);
        expect(
          minutos,
          inInclusiveRange(1, 30),
          reason: '«${guia.titulo}» mede $minutos min, o que não é um artigo',
        );
      }
    });

    test('conta só o <main>, não o cabeçalho nem o rodapé', () {
      const pagina = '''
<header>um dois três quatro cinco</header>
<main><p>seis sete</p></main>
<footer>oito nove dez</footer>''';
      expect(palavrasDe(pagina), 2);
    });

    test('não conta os comentários do HTML', () {
      // Este repositório escreve comentários longos; contá-los mediria a
      // conversa sobre o guia em vez do guia.
      const pagina = '<main><!-- um dois três quatro --><p>cinco</p></main>';
      expect(palavrasDe(pagina), 1);
    });

    test('a Saga não mostra minutos', () {
      // Somadas, as dezoito páginas davam «81 min de leitura» — ninguém lê
      // isso de uma vez, e lê-se como avaria.
      final saga = guias.firstWhere((g) => g.titulo.startsWith('Saga'));
      expect(saga.medida, isNotNull);
      final carta = RegExp(
        '<a class="guia" href="${RegExp.escape(saga.endereco)}".*?</a>',
        dotAll: true,
      ).firstMatch(emDisco)!.group(0)!;
      expect(carta.contains('min de leitura'), isFalse);
      expect(carta, contains('classes, uma página cada'));
    });
  });

  group('o filtro', () {
    test('a barra conta quantos guias há em cada versão', () {
      for (final versao in versoesOferecidas) {
        final quantos = guiasDe(versao).length;
        expect(
          emDisco,
          contains('data-ver="$versao"'),
          reason: 'a barra não oferece $versao',
        );
        expect(quantos, greaterThan(0));
      }
    });

    test('cada botão diz se está premido, e só um está', () {
      // A moldura acesa diz qual está escolhido a quem vê, e nada o dizia a
      // quem ouve — a mesma falta que `semanticLabel` tapa no glifo do sexo.
      expect(RegExp('aria-pressed="true"').allMatches(emDisco).length, 1);
      expect(
        RegExp('aria-pressed="false"').allMatches(emDisco).length,
        versoesOferecidas.length,
      );
    });

    test('«todos» é simplesmente não filtrar, e conta tudo', () {
      expect(emDisco, contains('data-ver="todos"'));
      expect(emDisco, contains('>${guias.length}</span>'));
    });

    test('o guia de todas as versões é marcado em cada uma delas', () {
      // Vazio no atributo seria «não serve nenhuma» para o JavaScript, que é
      // o contrário do que vazio quer dizer na declaração.
      final carta = RegExp(
        '<a class="guia" href="/multicontas"[^>]*>',
      ).firstMatch(emDisco)!.group(0)!;
      for (final versao in versoesOferecidas) {
        expect(carta, contains(versao));
      }
    });

    test('sem JavaScript a lista fica inteira à vista', () {
      // O filtro esconde ao toque; nenhuma carta nasce escondida. Ao
      // contrário, uma página sem script mostraria uma lista cortada e nada
      // diria porquê.
      final lista = RegExp(
        r'<!-- INÍCIO DA LISTA -->(.*)<!-- FIM DA LISTA -->',
        dotAll: true,
      ).firstMatch(emDisco)!.group(1)!;
      expect(lista.contains('hidden'), isFalse);
    });
  });
}
