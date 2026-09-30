import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/vitrine.dart';
import 'package:pw_market_filter/market/market_index.dart';

const _arma70 = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);
const _armaFraca = EquippedItem(
  slot: 10,
  itemId: 50100,
  refine: 0,
  stones: [],
  attributes: {0: 30},
);
const _armaDef80 = EquippedItem(
  slot: 10,
  itemId: 50300,
  refine: 12,
  stones: [],
  attributes: {1: 80},
);

MarketCharacter _quem(
  String nome,
  int preco, {
  List<EquippedItem> usa = const [_arma70],
}) => MarketCharacter(
  roleId: nome.hashCode,
  name: nome,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: preco,
  fame: 0,
  cultivation: 'Leal',
  equipped: usa,
);

MarketIndex _indice(List<MarketCharacter> quem) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 30),
  attributes: const ['Nível de Ataque', 'Nível de Defesa'],
  items: const {},
  characters: quem,
);

void main() {
  test('it picks the cheapest and the dearest of the SAME weapon tier', () {
    // The claim is "the same weapon, sixty times the price". Cheapest of the
    // whole market against dearest of the whole market would be a different
    // and false statement — they would not be carrying the same thing.
    final v = vitrineDe(
      _indice([
        _quem('barato', 130),
        _quem('meio', 900),
        _quem('caro', 8000),
        _quem('sem arma', 40, usa: const [_armaFraca]),
      ]),
    )!;

    expect(v.barato.name, 'barato');
    expect(v.caro.name, 'caro');
  });

  test('the rare one carries the defensive tier when anybody does', () {
    final v = vitrineDe(
      _indice([
        _quem('barato', 130),
        _quem('caro', 8000),
        _quem('raro', 2200, usa: const [_armaDef80]),
      ]),
    )!;

    expect(v.raro?.name, 'raro');
  });

  test('no rare one is null, not a stand-in', () {
    // A market with nobody on the defensive tier must draw two cards, never
    // three with the third repeating somebody.
    final v = vitrineDe(_indice([_quem('barato', 130), _quem('caro', 8000)]))!;

    expect(v.raro, isNull);
  });

  test('a market where nobody carries the tier shows no vitrine at all', () {
    // Better nothing than a claim about a pair that does not exist.
    expect(
      vitrineDe(
        _indice([
          _quem('a', 40, usa: const [_armaFraca]),
        ]),
      ),
      isNull,
    );
  });

  test('one carrier alone is not a spread and draws nothing', () {
    // "Sixty times the price" needs two people. One would make the cheapest
    // and the dearest the same character, which is not an argument.
    expect(vitrineDe(_indice([_quem('sozinho', 500)])), isNull);
  });

  test('an empty market is silent', () {
    expect(vitrineDe(_indice(const [])), isNull);
  });
}
