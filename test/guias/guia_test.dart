import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/guia.dart';

/// Pins the one declaration of the guides against the disk.
///
/// **Two lists of guides that did not know about each other already cost
/// something here**: the runes guide shipped and for days no path on the site
/// reached it, because the articles lived in `web/guias/index.html` and the
/// menu lived in `tool.dart`. This file is what makes a third list
/// impossible — a page on disk nobody declared, or a declaration pointing at
/// a page that is not there, fails the suite.
void main() {
  test('todo guia declarado tem página em disco', () {
    for (final guia in guias) {
      final arquivo = guia.arquivo;
      if (arquivo == null) continue;
      expect(
        File(arquivo).existsSync(),
        isTrue,
        reason: '«${guia.titulo}» aponta para $arquivo, que não existe',
      );
    }
  });

  test('toda página de guia em disco está declarada', () {
    // O defeito que este ficheiro existe para apanhar, visto do outro lado:
    // publicar um artigo e não haver caminho nenhum para ele.
    final declarados = {
      for (final g in guias)
        if (g.arquivo != null) g.arquivo!,
    };
    final emDisco = Directory('web/guias')
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('.html'))
        // `index.html` é a própria lista, não um guia.
        .where((p) => !p.endsWith('guias/index.html'));

    for (final pagina in emDisco) {
      expect(
        declarados,
        contains(pagina),
        reason:
            '$pagina existe e nenhum Guia a declara — publicado sem '
            'caminho a partir do site',
      );
    }
  });

  test('a Saga entra pelo índice dela e não por uma classe', () {
    // Quem chega não sabe qual classe quer até ver a tabela.
    final saga = guias.firstWhere((g) => g.titulo.startsWith('Saga'));
    expect(saga.endereco, '/guias/saga-do-heroi/');
    expect(saga.arquivo, 'web/guias/saga-do-heroi/index.html');
  });

  test('nenhum endereço repetido', () {
    final enderecos = guias.map((g) => g.endereco).toList();
    expect(enderecos.toSet(), hasLength(enderecos.length));
  });

  group('as versões', () {
    test('só as multi contas servem as três', () {
      final todas = guias.where((g) => g.versoes.isEmpty).toList();
      expect(todas.map((g) => g.titulo), ['Multi contas']);
    });

    test('a página /guias/ é simplesmente não filtrar', () {
      expect(guiasDe(null), hasLength(guias.length));
    });

    test('o 1.2.6 recebe os que falam do cliente, não os do 1.8.7', () {
      final seis = guiasDe('1.2.6');
      expect(seis.map((g) => g.titulo), ['Multi contas']);
      // Uma versão sem guias próprios ainda recebe o que serve todas — e é
      // por isso que a secção dela não nasce vazia.
      expect(seis, isNotEmpty);
    });

    test('uma versão que ainda não abriu já responde', () {
      // O 1.4.4 abre a 13/11/2026 e não tem rota nenhuma ainda. A lista
      // responde-lhe de qualquer maneira, porque a versão é um campo do guia.
      expect(guiasDe('1.4.4').map((g) => g.titulo), ['Multi contas']);
    });

    test('nenhuma versão declarada é desconhecida', () {
      const conhecidas = {'1.8.7', '1.2.6', '1.4.4'};
      for (final guia in guias) {
        expect(guia.versoes, everyElement(isIn(conhecidas)));
      }
    });
  });

  group('o selo novo', () {
    test('apaga-se sozinho um mês depois, sem ninguém o tirar', () {
      final runas = guias.firstWhere((g) => g.endereco == '/guias/runas');
      expect(runas.novoEm(DateTime.utc(2026, 11, 9)), isTrue);
      // 22/10 + 30 dias. Hoje a página mostra seis selos `novo` escritos à
      // mão no HTML: nenhum deles expira, e a 22/11 o primeiro passa a
      // mentir sem que nada o diga.
      expect(runas.novoEm(DateTime.utc(2026, 11, 22)), isFalse);
    });

    test('o Início rápido, de Agosto, já não é novo', () {
      final inicio = guias.firstWhere(
        (g) => g.endereco == '/guias/inicio-rapido',
      );
      expect(inicio.novoEm(DateTime.utc(2026, 11, 9)), isFalse);
    });
  });

  test('só a Saga troca o tempo de leitura por uma medida', () {
    // Somar as dezoito páginas dava «81 min de leitura». Um conjunto não tem
    // duração, tem tamanho — e um segundo caso tem de ser decisão, não
    // descuido.
    final comMedida = guias.where((g) => g.medida != null);
    expect(comMedida.map((g) => g.titulo), ['Saga do Herói: as 17 classes']);
  });
}
