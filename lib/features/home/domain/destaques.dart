import 'package:flutter/material.dart' show Color;

import '../../../core/theme/pw_colors.dart';
import '../../../market/market_index.dart';
import '../../../market/slot_names.dart';
import '../../search/domain/matcher.dart';
import '../../search/domain/presets.dart';
import '../../search/domain/search_query.dart';
import 'visit_label.dart' show groupThousands;

/// One card of the front page's six: a question about the market, already
/// answered by somebody real.
class Destaque {
  const Destaque({
    required this.rotulo,
    required this.personagem,
    required this.nota,
    required this.cor,
    required this.busca,
    this.selo,
  });

  /// What this card answers. Softens from *o mais barato* to *dos mais
  /// baratos* when a class collision pushed it past the true winner — see
  /// [destaquesDe]. A label that still claimed "the cheapest" after moving
  /// off the cheapest would be the card lying about itself.
  final String rotulo;
  final MarketCharacter personagem;

  /// The line under the price, and it must be derivable from this collection.
  final String nota;

  /// The frame, from the game's own rarity palette — the same colours the
  /// results card already paints, so somebody arriving at the filter
  /// recognises them.
  final Color cor;

  /// Where tapping leads. Every card is a door into the filter.
  final SearchQuery busca;

  /// The corner badge. `null` draws none.
  final String? selo;
}

/// The attribute every "70" and "UP5" question is asked about.
const _nivelDeAtaque = 'Nível de Ataque';
const _nivelDeDefesa = 'Nível de Defesa';
const _chaveDaSorte = 'Chave da Sorte';

/// The six characters the front page shows, one per question.
///
/// **No two cards may share a class, and that is not a nicety.** The art is
/// the card here, so two cards of one class are two identical pictures side
/// by side — which promises a difference that is not there, the same defect
/// as the pet eggs sharing one sprite. Measured on 2026-09-30: the Arcano was
/// simultaneously the cheapest carrier of a 70 weapon *and* the cheapest
/// carrier of the defensive UP5, so the collision is not hypothetical.
///
/// When a category's true winner is already on screen, the card falls to the
/// next cheapest (or next best) of a class nobody has used, **and its label
/// softens** — *o mais barato* becomes *dos mais baratos*, because it no
/// longer is the cheapest and a card that says otherwise is lying with a real
/// number beside it. A category with no untaken class left is dropped rather
/// than repeated.
///
/// Empty is an answer: a market with nobody at a tier draws fewer cards,
/// never a hole and never an exception.
///
/// The six categories are walked **in a fixed order** — the table's order —
/// because the order decides who cedes a class to whom in a collision, and
/// that has to be stable rather than alphabetical or incidental.
List<Destaque> destaquesDe(MarketIndex index) {
  final destaques = <Destaque>[];
  final usadas = <String>{};

  // 1. O mais barato — the cheapest character of the whole market.
  final todosPorPreco = runQuery(index, const SearchQuery());
  _tentar(
    destaques,
    usadas,
    todosPorPreco,
    rotuloCheio: 'O mais barato',
    rotuloSuave: 'Um dos mais baratos',
    cor: PWColors.grade(0),
    busca: const SearchQuery(),
    nota: (_, _) =>
        '${groupThousands(index.characters.length)} personagens no mercado',
  );

  // 2. Arma de 70 mais barata.
  final arma70 = strongWeaponQuery(index);
  if (arma70 != null) {
    final carregadores = runQuery(index, arma70);
    _tentar(
      destaques,
      usadas,
      carregadores,
      rotuloCheio: 'Arma de 70 mais barata',
      rotuloSuave: 'Um dos mais baratos com arma de 70',
      cor: PWColors.grade(3),
      busca: arma70,
      selo: (_) => 'ARMA 70',
      nota: (_, _) => '${carregadores.length} no mercado inteiro',
    );
  }

  // 3. Atq lvl UP5 mais barato.
  final atqUp5 = weaponQuery(index, _nivelDeAtaque, 80);
  if (atqUp5 != null) {
    final carregadores = runQuery(index, atqUp5);
    _tentar(
      destaques,
      usadas,
      carregadores,
      rotuloCheio: 'Atq lvl UP5 mais barato',
      rotuloSuave: 'Um dos mais baratos com Atq lvl UP5',
      cor: PWColors.grade(6),
      busca: atqUp5,
      selo: (_) => 'ATQ UP5',
      nota: (_, _) => '${carregadores.length} no mercado inteiro',
    );
  }

  // 4. Def lvl UP5 mais barato.
  final defUp5 = weaponQuery(index, _nivelDeDefesa, 80);
  if (defUp5 != null) {
    final carregadores = runQuery(index, defUp5);
    _tentar(
      destaques,
      usadas,
      carregadores,
      rotuloCheio: 'Def lvl UP5 mais barato',
      rotuloSuave: 'Um dos mais baratos com Def lvl UP5',
      cor: PWColors.defenceTier,
      busca: defUp5,
      selo: (_) => 'DEF UP5',
      nota: (_, _) => '${carregadores.length} no mercado inteiro',
    );
  }

  // 5. O mais caro — the dearest character of the whole market.
  const buscaDoMaisCaro = SearchQuery(order: ResultOrder.dearest);
  final todosPorPrecoDesc = runQuery(index, buscaDoMaisCaro);
  _tentar(
    destaques,
    usadas,
    todosPorPrecoDesc,
    rotuloCheio: 'O mais caro',
    rotuloSuave: 'Um dos mais caros',
    cor: PWColors.accent,
    busca: buscaDoMaisCaro,
    nota: (vencedor, _) {
      // Conditional and derived: a wrong claim about the market's own top
      // would be a sentence tomorrow's collection could contradict.
      final nivel = _nivelDeAtaqueDoVencedor(index, vencedor);
      return nivel >= 70 ? 'O topo do mercado' : 'E não é o mais forte';
    },
  );

  // 6. Mais Chaves da Sorte — most of a counted item, never a filter.
  final porChaves = _carregadoresDeChaves(index);
  _tentar(
    destaques,
    usadas,
    porChaves,
    rotuloCheio: 'Mais Chaves da Sorte',
    rotuloSuave: 'Um dos que mais carregam Chaves da Sorte',
    cor: PWColors.grade(2),
    busca: const SearchQuery(shownOwned: {_chaveDaSorte}),
    selo: (vencedor) =>
        groupThousands(index.countOf(vencedor, _chaveDaSorte) ?? 0),
    nota: (_, _) => '${porChaves.length} personagens carregam alguma',
  );

  return destaques;
}

/// Tries to add one [Destaque] to [destaques] from [candidatos], an
/// already-ordered list where the first entry is the true winner of the
/// category.
///
/// Walks past every candidate whose class is already in [usadas] — that is
/// the class-collision rule — and softens the label the moment it has to
/// skip at least one. When every candidate's class has already been used,
/// the category is dropped rather than repeating a class already on screen.
void _tentar(
  List<Destaque> destaques,
  Set<String> usadas,
  List<MarketCharacter> candidatos, {
  required String rotuloCheio,
  required String rotuloSuave,
  required Color cor,
  required SearchQuery busca,
  required String Function(MarketCharacter vencedor, bool empurrado) nota,
  String? Function(MarketCharacter vencedor)? selo,
}) {
  var empurrado = false;
  for (final candidato in candidatos) {
    if (usadas.contains(candidato.characterClass)) {
      empurrado = true;
      continue;
    }

    usadas.add(candidato.characterClass);
    destaques.add(
      Destaque(
        rotulo: empurrado ? rotuloSuave : rotuloCheio,
        personagem: candidato,
        nota: nota(candidato, empurrado),
        cor: cor,
        busca: busca,
        selo: selo?.call(candidato),
      ),
    );
    return;
  }
  // No candidate left of a class nobody has used: the category draws
  // nothing, same as a market with nobody at the tier at all.
}

/// The attack level actually worn on [character]'s weapon, 0 when this
/// collection never met the attribute or the slot carries none.
///
/// Read off the weapon slot alone, the same rule `weaponTierColor` follows: a
/// criterion may ask about any piece, but a statement about "the dearest
/// character's weapon" has to be read off the weapon, not off whichever item
/// happens to carry the attribute.
int _nivelDeAtaqueDoVencedor(MarketIndex index, MarketCharacter character) {
  final id = index.attributes.indexOf(_nivelDeAtaque);
  if (id < 0) return 0;
  for (final item in character.equipped) {
    if (item.slot != weaponSlot) continue;
    return item.attributes[id] ?? 0;
  }
  return 0;
}

/// Carriers of at least one `Chave da Sorte`, most first.
///
/// Built by hand rather than through `ResultOrder`: there is no "most keys"
/// order in the filter, because `ResultOrder.mostOwned` sums the three relics
/// on purpose and the key is deliberately not one of them
/// (`counted_items.dart` says why). Somebody carrying zero is not a carrier —
/// the same call the matcher makes for every `minimumOwned` filter.
List<MarketCharacter> _carregadoresDeChaves(MarketIndex index) {
  if (!index.countedItems.containsKey(_chaveDaSorte)) return const [];

  final comContagem = <(MarketCharacter, int)>[];
  for (final character in index.characters) {
    final contagem = index.countOf(character, _chaveDaSorte);
    if (contagem != null && contagem > 0) {
      comContagem.add((character, contagem));
    }
  }
  comContagem.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final par in comContagem) par.$1];
}
