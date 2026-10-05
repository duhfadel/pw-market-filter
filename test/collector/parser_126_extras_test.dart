import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser_126.dart';

/// The three things the 1.2.6 players asked for, read off real pages.
///
/// None of them exists on a 1.8.7 page — zero occurrences of `Itens do
/// Personagem`, `data-pet-name` or the per-skill badges in either 1.8.7
/// fixture — which is why the state's stamp is per marketplace.
void main() {
  late String redDusk; // 62224, Feiticeira nv103, with a Hércules
  late String softEA; // 5424
  late String vayne; // 229217

  setUpAll(() {
    redDusk = File('test/fixtures/detail_pw126_62224.html').readAsStringSync();
    softEA = File('test/fixtures/detail_pw126_5424.html').readAsStringSync();
    vayne = File('test/fixtures/detail_pw126_229217.html').readAsStringSync();
  });

  group('os espaços de itens', () {
    test('lê os quatro pares, usados e capacidade', () {
      final espacos = parseEspacos126(redDusk);

      expect(espacos['Inventário']!.usados, 27);
      expect(espacos['Inventário']!.capacidade, 64);
      expect(espacos['Banqueiro']!.capacidade, 72);
      expect(espacos['Roupas']!.capacidade, 80);
      expect(espacos['Materiais']!.capacidade, 96);
    });

    test('o Equipamento é uma contagem, não uma loja', () {
      // Não imprime capacidade nenhuma, e é lido com zero em vez de ser
      // descartado — custa nada e poupa ao coletor contá-lo sozinho.
      expect(parseEspacos126(redDusk)['Equipamento']!.usados, 17);
      expect(parseEspacos126(redDusk)['Equipamento']!.capacidade, 0);
    });

    test('a capacidade varia entre personagens, e é esse o facto que vale', () {
      // Expandir custa dinheiro no jogo. Medido em nove páginas: a mochila
      // anda por 32, 40, 48 e 64.
      final a = parseEspacos126(redDusk)['Inventário']!.capacidade;
      final b = parseEspacos126(softEA)['Inventário']!.capacidade;
      expect(a, isNot(b));
    });

    test('zero é uma resposta real, não um campo em falta', () {
      // Quatro dos nove medidos nunca abriram Roupas nem Materiais.
      expect(parseEspacos126(softEA)['Roupas']!.capacidade, 0);
      expect(parseEspacos126(softEA)['Materiais']!.capacidade, 0);
    });

    test('uma página sem a secção devolve vazio, não zeros', () {
      expect(parseEspacos126('<html><body>nada</body></html>'), isEmpty);
    });
  });

  group('os mascotes', () {
    test('o Hércules aparece pelo nome que a página escreve', () {
      // **Esta versão nomeia a espécie onde o 1.8.7 deixa o dono rebaptizar
      // o ovo** — por isso ali o filtro tem de ir por id e aqui pode ir por
      // nome. Vale saber antes de copiar uma regra para a outra.
      final nomes = parseMascotes126(redDusk).map((m) => m.nome);

      expect(nomes, contains('Ovo de Hércules'));
    });

    test('distingue montaria de mascote de combate', () {
      final todos = parseMascotes126(redDusk);

      expect(todos.any((m) => m.montaria), isTrue);
      expect(todos.any((m) => !m.montaria), isTrue);
    });

    test('um personagem sem jaula devolve lista vazia', () {
      expect(parseMascotes126('<html><body>nada</body></html>'), isEmpty);
    });
  });

  group('as perícias', () {
    test('as quatro forjas estão lá, por id', () {
      // 158, 159, 160 e 161, achadas cruzando quatro classes diferentes:
      // cinco ids sobrevivem à intersecção e quatro deles são consecutivos.
      final pericias = parsePericias126(redDusk);

      for (final id in [158, 159, 160, 161]) {
        expect(pericias, contains(id), reason: 'perícia $id');
        expect(pericias[id], inInclusiveRange(1, 8));
      }
    });

    test('variam de forma independente, portanto são quatro e não uma', () {
      final a = parsePericias126(redDusk);
      final b = parsePericias126(vayne);
      expect([
        a[158],
        a[159],
        a[160],
        a[161],
      ], isNot([b[158], b[159], b[160], b[161]]));
    });

    test('nada aqui inventa o nome de uma perícia', () {
      // A página não publica nomes. Guardar por id é o que torna nomeá-las
      // um rebuild em vez de outra varredura.
      expect(parsePericias126(redDusk), isNotEmpty);
      expect(parsePericias126(redDusk)[158], isNotNull);
    });
  });
}
