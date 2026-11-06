import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/ultima_leitura.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// O arrasto do sexo e do reino, pedido pelo dono a 06/11/2026 nos termos
/// certos: *«se não chega esses campos, deixamos vazio até que se resolva no
/// site deles»* — e a última leitura boa é melhor do que vazio, porque
/// nenhum destes dois campos pode mudar para trás.
MarketCharacter _personagem(int roleId, {String sex = '', String realm = ''}) =>
    MarketCharacter(
      roleId: roleId,
      name: 'n$roleId',
      characterClass: 'Bardo',
      occupation: 0,
      cultivation: '',
      level: 105,
      price: 10,
      fame: 0,
      equipped: const [],
      sex: sex,
      realm: realm,
    );

MarketIndex _indice(List<MarketCharacter> cs) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 11, 6),
  attributes: const [],
  items: const {},
  characters: cs,
);

void main() {
  group('o que se arrasta', () {
    test('uma leitura fresca ganha sempre, mesmo discordando da anterior', () {
      // É ela que vê o jogo de hoje. O arrasto só preenche ausência.
      expect(comArrasto('Céu Devoto V', 'Céu Real I'), 'Céu Devoto V');
    });

    test('a ausência é preenchida pela anterior', () {
      expect(comArrasto('', 'Masculino'), 'Masculino');
    });

    test('sem anterior, a ausência continua ausente', () {
      // Um personagem novo numa coleta que não lê o campo não ganha um valor
      // inventado: fica vazio, e a tela desenha nada em vez de um palpite.
      expect(comArrasto('', null), isEmpty);
      expect(comArrasto('', ''), isEmpty);
    });

    test('só quem tem algo a arrastar entra na tabela', () {
      final tabela = ultimasLeiturasDe(
        _indice([
          _personagem(1, sex: 'Masculino', realm: 'Céu Real I'),
          _personagem(2),
        ]),
      );

      expect(tabela.keys, [1]);
      expect(tabela[1]!.sex, 'Masculino');
    });

    test('nunca tendo publicado, não há nada a arrastar', () {
      // O mesmo que `publicado == null` já significa no resto do coletor:
      // ninguém foi visto ainda.
      expect(ultimasLeiturasDe(null), isEmpty);
    });
  });

  group('o censo', () {
    test('conta o que esta coleta leu, nunca o que foi arrastado', () {
      final censo = censoDosCampos(const [
        UltimaLeitura(sex: 'Masculino', realm: 'Céu Real I'),
        UltimaLeitura(sex: 'Feminino', realm: ''),
        UltimaLeitura(sex: '', realm: ''),
      ]);

      expect(censo['sexo'], 2);
      expect(censo['reino'], 1);
    });

    test('uma leitura que colapsa dá zero, que é o que tem de aparecer', () {
      // O caso de 06/11: zero de 2.879 nos dois campos. Com o arrasto, o
      // índice sai completo e o defeito ficaria invisível — é este número
      // que o coletor imprime para que não fique.
      final censo = censoDosCampos([
        for (var i = 0; i < 5; i++) const UltimaLeitura(sex: '', realm: ''),
      ]);

      expect(censo['sexo'], 0);
      expect(censo['reino'], 0);
    });
  });
}
