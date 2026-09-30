import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/collector/memoria.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

final _hoje = DateTime.utc(2026, 10, 1);
final _ontem = DateTime.utc(2026, 9, 30);

ListingCard _card(int roleId, int price) => ListingCard(
  roleId: roleId,
  name: 'n$roleId',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: price,
  fame: 0,
  cultivation: 'Leal',
);

MarketIndex _publicado(List<MarketCharacter> quem, {DateTime? desde}) =>
    MarketIndex(
      server: 'pw187',
      collectedAt: _ontem,
      attributes: const [],
      items: const {},
      characters: quem,
      historyFrom: desde,
    );

MarketCharacter _quem(int roleId, int price, {PriceHistory? history}) =>
    MarketCharacter(
      roleId: roleId,
      name: 'n$roleId',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: price,
      fame: 0,
      cultivation: 'Leal',
      equipped: const [],
      history: history,
    );

void main() {
  test('with no published index, everybody starts a record today', () {
    final r = avancarTodos(
      listing: [_card(1, 500), _card(2, 400)],
      publicado: null,
      agora: _hoje,
    );

    expect(r[1]!.firstSeen, _hoje);
    expect(r[2]!.lowestPrice, 400);
    expect(r[1]!.cuts, 0);
  });

  test('a published index with characters but no history is still a genuine '
      'first run, not a failure — every character starts a record today', () {
    // This is the shape a successful 200 fetch takes the very first time
    // the site's own index is read by this feature: the characters are
    // real, but none of them carry a `history` yet and `historyFrom` is
    // `null`. It must behave exactly like `publicado: null` — the two are
    // the "nobody has been recorded yet" case — and must never be confused
    // with a failed read, which `avancarTodos` never even sees: a failure
    // stops the run before this function is called.
    final publicado = _publicado([_quem(1, 500), _quem(2, 400)]);

    final r = avancarTodos(
      listing: [_card(1, 500), _card(2, 400)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[1]!.firstSeen, _hoje);
    expect(r[1]!.previousPrice, isNull);
    expect(r[2]!.lowestPrice, 400);
    expect(r[2]!.cuts, 0);
  });

  test('a price that fell since the published index is a cut', () {
    final publicado = _publicado([
      _quem(1, 500, history: PriceHistory(firstSeen: _ontem, lowestPrice: 500)),
    ], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(1, 400)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[1]!.previousPrice, 500);
    expect(r[1]!.lowestPrice, 400);
    expect(r[1]!.cuts, 1);
    expect(r[1]!.firstSeen, _ontem, reason: 'first seen never moves');
  });

  test('somebody who left and came back keeps their floor', () {
    // `pruneTo` forgets a departed character from the state file, but the
    // published index still holds them until the next publish. Losing the
    // floor would call an old listing new and reset what is known about it.
    final publicado = _publicado([
      _quem(
        9,
        800,
        history: PriceHistory(
          firstSeen: DateTime.utc(2026, 9, 1),
          lowestPrice: 300,
          cuts: 3,
        ),
      ),
    ], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(9, 800)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[9]!.firstSeen, DateTime.utc(2026, 9, 1));
    expect(r[9]!.lowestPrice, 300);
    expect(r[9]!.cuts, 3);
  });

  test('a character the published index never had starts fresh', () {
    final publicado = _publicado([_quem(1, 500)], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(1, 500), _card(2, 120)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[2]!.firstSeen, _hoje);
    expect(r[2]!.previousPrice, isNull);
  });

  test('the first run that keeps records is the date that is stamped', () {
    expect(historyFromDe(null, _hoje), _hoje);
    expect(historyFromDe(_publicado(const []), _hoje), _hoje);
  });

  test('a later run carries the original date forward, never today', () {
    // Restamping every run would make every character look like it arrived
    // before we were watching, for ever.
    final publicado = _publicado(const [], desde: DateTime.utc(2026, 9, 15));

    expect(historyFromDe(publicado, _hoje), DateTime.utc(2026, 9, 15));
  });
}
