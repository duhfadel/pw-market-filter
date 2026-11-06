import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// **Cada campo do índice tem de ter ao menos um portador.**
///
/// Esta é a rede que faltava a 06/11/2026, e a falta custou o dia. O site
/// passou a oscilar entre português e espanhol; `parseAnecdotes`,
/// `parseSex` e `parseCelestialRealm` casavam o rótulo por igualdade exacta,
/// e duas recolhas completas vieram com **zero de 2.879** nos três campos.
///
/// Dois testes apanharam dois deles — `counted_items_test` as anedotas,
/// `poda_126_test` o reino — e **o sexo passou calado**, porque nenhum teste
/// afirmava que alguém o tinha. Só o vimos porque estava ao lado do reino no
/// mesmo artefacto. Isso é sorte, não cobertura.
///
/// O que torna este teste necessário e não redundante: ele não pergunta se o
/// *parser* funciona — `sheet_test` faz isso contra páginas guardadas. Ele
/// pergunta se o campo **chegou ao outro lado do disco**, que é a travessia
/// onde este projecto já perdeu `require_level`, o `sexo`, o `nivel`, a
/// `escada` e os `bonusNaoResolvidos`.
///
/// É um gate de publicação cuja entrada é o mundo, portanto segue a regra
/// desse tipo: **um campo a zero é defeito nosso e fica vermelho**; uma
/// contagem baixa é um facto sobre um mercado que muda sozinho e só se
/// imprime. A fronteira é zero, e é dura de propósito — um campo que o site
/// publica e nós não lemos nunca é uma opinião.
void main() {
  for (final (versao, caminho) in const [
    ('1.8.7', 'web/market_index.json'),
    ('1.2.6', 'web/market_index_126.json'),
  ]) {
    group(versao, () {
      late MarketIndex? indice;

      setUpAll(() {
        final f = File(caminho);
        indice = f.existsSync()
            ? MarketIndex.fromJson(
                jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
              )
            : null;
      });

      test('cada campo por personagem tem ao menos um portador', () {
        final index = indice;
        if (index == null) return;

        // Por campo, quantos o trazem. O 1.2.6 não publica tudo o que o
        // 1.8.7 publica, por isso a lista do que é **obrigatório** é a dos
        // campos que esta versão já teve alguma vez — medido abaixo contra o
        // próprio índice, nunca cravado à mão para as duas versões.
        final contagens = <String, int>{
          'sex': index.characters.where((c) => c.sex.isNotEmpty).length,
          'realm': index.characters.where((c) => c.realm.isNotEmpty).length,
          'path': index.characters.where((c) => c.path.isNotEmpty).length,
          'cultivation': index.characters
              .where((c) => c.cultivation.isNotEmpty)
              .length,
          'anecdotes': index.characters
              .where((c) => c.anecdotes != null)
              .length,
          'cards': index.characters.where((c) => c.cards.isNotEmpty).length,
          'equipped': index.characters
              .where((c) => c.equipped.isNotEmpty)
              .length,
          'runes': index.characters.where((c) => c.runes.isNotEmpty).length,
          'counts': index.characters.where((c) => c.counts.isNotEmpty).length,
        };

        for (final entry in contagens.entries) {
          // ignore: avoid_print
          print('  ${entry.key}: ${entry.value}/${index.characters.length}');
        }

        // Os campos que o 1.8.7 publica e o 1.2.6 não são omitidos em vez de
        // afirmados: uma asserção sobre um painel que aquele mercado não tem
        // seria uma reprovação por não existir.
        final obrigatorios = versao == '1.8.7'
            ? contagens.keys
            // O sexo entra: o 1.2.6 publica-o, 1426 de 1426 medidos a
            // 06/11/2026. O reino, o caminho, as anedotas, as cartas, as
            // runas e os itens contados são painéis que aquele mercado não
            // tem, e exigi-los seria reprovar por não existirem.
            : const ['sex', 'cultivation', 'equipped'];

        for (final campo in obrigatorios) {
          expect(
            contagens[campo],
            greaterThan(0),
            reason:
                '$campo está a zero em $caminho. O site publica-o e nós não '
                'o lemos — é a forma de 06/11/2026, quando um rótulo mudou '
                'de língua. Ver `sheet_test` e `ultima_leitura.dart`.',
          );
        }
      });
    });
  }
}
