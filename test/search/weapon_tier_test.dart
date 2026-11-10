import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/search/ui/widgets/character_card.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The frame that tells a grid of forty cards apart.
///
/// It shipped with no test at all, and the rung that needed one most is the
/// defensive UP5: eight characters in 1519, which is a case nobody meets by
/// scrolling the page. A colour that silently fell through to the attack
/// ladder would look like a working frame.
const _atributos = ['Nível de Ataque', 'Nível de Defesa', 'HP'];
const _ataque = 0;
const _defesa = 1;
const _hp = 2;

MarketIndex _index() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 29),
  attributes: _atributos,
  items: {},
  characters: [],
);

/// A character wearing one weapon giving [attributes], plus — when asked — a
/// second piece that is not a weapon.
MarketCharacter _wearing(
  Map<int, List<double>> attributes, {
  Map<int, List<double>>? noAmuleto,
}) => MarketCharacter(
  roleId: 1,
  name: 'Alvo',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 0,
  cultivation: 'Leal',
  equipped: [
    EquippedItem(
      slot: 10,
      itemId: 50206,
      refine: 0,
      stones: const [],
      attributes: attributes,
    ),
    if (noAmuleto != null)
      EquippedItem(
        slot: 8,
        itemId: 45306,
        refine: 0,
        stones: const [],
        attributes: noAmuleto,
      ),
  ],
);

void main() {
  final index = _index();

  test('a escada de ataque, remedida a 09/11/2026', () {
    // **O 70 perdeu o âmbar e ficou com o roxo**, porque passou a ser 44,5%
    // do mercado: a cor mais quente da paleta na coisa mais vulgar da grelha
    // dizia *raro* sobre o normal. E o âmbar era `#FFB454`, que é
    // `PWColors.accent` ao byte — a moldura era a cor do preço ao lado.
    expect(
      patamarDaArma(
        index,
        _wearing({
          _ataque: [80],
        }),
      ),
      PatamarDaArma.ataque80,
    );
    expect(
      patamarDaArma(
        index,
        _wearing({
          _ataque: [70],
        }),
      ),
      PatamarDaArma.setenta,
    );
    expect(
      patamarDaArma(
        index,
        _wearing({
          _ataque: [40],
        }),
      ),
      PatamarDaArma.baixo,
    );
  });

  test('o âmbar saiu da escada e não volta por acidente', () {
    // Um `switch` que ganhasse um degrau de volta devolveria a cor do
    // dinheiro à grelha sem nada o dizer.
    for (final patamar in PatamarDaArma.values) {
      expect(
        patamar.cor,
        isNot(PWColors.accent),
        reason: '$patamar usa a cor do preço',
      );
    }
  });

  test('só o fundo da escada deixa o card por tingir', () {
    // 51,8% do mercado está em `baixo`. Tingir-lhe o fundo poria cor em
    // metade da grelha e deixaria os 3,7% que são 80 sem por onde se
    // distinguirem — a borda azul já diz o que havia a dizer.
    expect(PatamarDaArma.baixo.pinta, isFalse);
    for (final patamar in PatamarDaArma.values) {
      if (patamar == PatamarDaArma.baixo) continue;
      expect(patamar.pinta, isTrue, reason: '$patamar devia tingir');
    }
  });

  test('the defensive UP5 is not the attacking one', () {
    // The whole reason this rung exists. Eight characters carry it, they are
    // 2.200 to 20.000 TCC, and a frame that painted them red would say they
    // were something they are not.
    expect(
      patamarDaArma(
        index,
        _wearing({
          _defesa: [80],
        }),
      ),
      PatamarDaArma.defesa80,
    );
    expect(
      patamarDaArma(
        index,
        _wearing({
          _defesa: [80],
        }),
      ),
      isNot(PatamarDaArma.ataque80),
    );
  });

  test('defence wins when a weapon somehow carries both', () {
    // Disjoint in every collection so far, and the ordering must not depend on
    // that staying true.
    expect(
      patamarDaArma(
        index,
        _wearing({
          _ataque: [80],
          _defesa: [80],
        }),
      ),
      PatamarDaArma.defesa80,
    );
  });

  test('o 30, o 40 e o 69 caem todos no mesmo degrau de baixo', () {
    // **Isto reverte a decisão de 29/09/2026**, que tirou a cor ao 30 com o
    // argumento de que *o fundo do mercado não precisa de um selo dizendo que
    // é o fundo*. O fundo deixou de ser um canto: com o 30, o 40-69 e os
    // sem-nível juntos são 51,8% da grelha, e o dono pediu azul para todos a
    // 09/11/2026. O 40 deixou de ser degrau próprio no mesmo movimento.
    for (final nivel in <double>[30, 39, 40, 69]) {
      expect(
        patamarDaArma(
          index,
          _wearing({
            _ataque: [nivel],
          }),
        ),
        PatamarDaArma.baixo,
        reason: 'ataque $nivel',
      );
    }
  });

  test('uma arma que não publica nível nenhum é azul, não é ausência', () {
    // **Decisão do dono a 09/11/2026, contra a recomendação.** São 409 de
    // 2.486 — 16,5% — e a `★★★Geada Tardia` é rank 4 e não dá nível de
    // ataque, portanto o azul aqui afirma *fundo da escada* sobre uma coisa
    // que ninguém mediu. O argumento dele é que numa grelha onde alguma cor é
    // a norma, a ausência de cor lê-se como card partido.
    expect(
      patamarDaArma(
        index,
        _wearing({
          _hp: [5000],
        }),
      ),
      PatamarDaArma.baixo,
    );
    expect(patamarDaArma(index, _wearing(const {})), PatamarDaArma.baixo);
  });

  test('sem arma vestida continua a ser ausência', () {
    // O que separa isto do teste acima é haver ou não o que ler. Uma arma
    // lida que não publica nível é um facto sobre a arma; nenhuma arma é a
    // falta do próprio sujeito, e uma borda ali afirmaria um degrau sobre
    // quem não tem arma.
    final semArma = MarketCharacter(
      roleId: 2,
      name: 'Desarmado',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: 100,
      fame: 0,
      cultivation: 'Leal',
      equipped: const [],
    );

    expect(patamarDaArma(index, semArma), isNull);
    expect(weaponTierColor(index, semArma), isNull);
  });

  test('the low defence rolls are noise and never reach a real rung', () {
    // `Nível de Defesa` on a weapon runs 1 to 30 and then jumps straight to
    // 80. Reading the low end as a tier would paint a quarter of the market
    // for a roll nobody buys on. Cai em `baixo`, que é onde pertence: uma
    // arma lida que não chega a lado nenhum.
    for (final roll in <double>[1, 5, 20, 30]) {
      expect(
        patamarDaArma(
          index,
          _wearing({
            _defesa: [roll],
          }),
        ),
        PatamarDaArma.baixo,
        reason: 'defence $roll is noise',
      );
    }
  });

  test('only the weapon speaks for the frame', () {
    // A criterion may ask about any piece; the frame is a statement about the
    // weapon. An amulet's attack level vouching for it would be the same
    // fraud the matcher refuses when it reads every condition off one item.
    expect(
      patamarDaArma(
        index,
        _wearing(
          const {},
          noAmuleto: {
            _ataque: [80],
          },
        ),
      ),
      PatamarDaArma.baixo,
      reason: 'o amuleto não pode promover a arma a 80',
    );
  });

  test('a collection that never met the attribute colours nothing', () {
    // `indexOf` answers -1, and a frame is not worth a crash.
    final semAtributos = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 9, 29),
      attributes: const ['HP'],
      items: {},
      characters: [],
    );

    expect(
      weaponTierColor(
        semAtributos,
        _wearing({
          0: [80],
        }),
      ),
      isNull,
    );
  });
}
