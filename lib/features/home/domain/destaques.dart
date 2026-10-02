import 'package:flutter/material.dart' show Color;

import '../../../market/counted_items.dart';
import '../../../market/market_index.dart';
import '../../../market/slot_names.dart';
import '../../search/domain/matcher.dart';
import '../../search/domain/presets.dart';
import '../../search/domain/search_query.dart';
import '../../search/ui/widgets/character_card.dart' show weaponTierColor;
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

  /// The frame: exactly `weaponTierColor(index, personagem)`, the same
  /// ladder the results grid already paints — called, never restated.
  ///
  /// **This is the one colour the front page is allowed to show about a
  /// character, and it is a fact about that character's weapon, not about
  /// which of the six questions the card answers.** A parallel ladder here
  /// would be two copies of one fact, free to drift the day either one is
  /// edited — the exact failure this repo's `weaponTierColor` doc already
  /// warns about. `null` when the character carries no tier at all, which
  /// draws the plain border: a colour on somebody with no tier would be the
  /// lie, not the omission.
  ///
  /// Two cards can land on the same colour — the dearest character and the
  /// Atq UP5 carrier can both genuinely wear an 80 — and that is correct.
  /// The label and the badge are what say which question a card answers; the
  /// frame only ever says what the person is actually wearing.
  final Color? cor;

  /// Where tapping leads. Every card is a door into the filter.
  final SearchQuery busca;

  /// The corner badge. `null` draws none.
  final String? selo;
}

/// The attribute every "70" and "UP5" question is asked about.
const _nivelDeAtaque = 'Nível de Ataque';
const _nivelDeDefesa = 'Nível de Defesa';

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
    index,
    todosPorPreco,
    rotuloCheio: (_) => 'O mais barato',
    rotuloSuave: (_) => 'Um dos mais baratos',
    busca: const SearchQuery(),
    nota: (_, _) => '${groupThousands(index.characters.length)} no mercado',
  );

  // 2. Arma de 70 mais barata — the label's "70" is derived from the winner,
  // never hardcoded. `strongWeaponQuery` asks **at least** 70, and the market
  // has an 80 tier above it: a cheapest-first search can land on an 80
  // carrier the moment nobody cheaper wears exactly 70, which would make a
  // fixed "ARMA 70" badge the fourth appearance of the shape CLAUDE.md
  // already records three times — a label stating a number the data does not
  // support. True on every collection measured so far (SK_Alya, 45 TCC,
  // exactly 70), but latent is still wrong the day it changes, so the badge
  // reads `_nivelDeAtaqueDoVencedor`, the same call category 5 already makes.
  final arma70 = strongWeaponQuery(index);
  if (arma70 != null) {
    final carregadores = runQuery(index, arma70);
    _tentar(
      destaques,
      usadas,
      index,
      carregadores,
      rotuloCheio: (vencedor) =>
          'Arma de ${_nivelDeAtaqueDoVencedor(index, vencedor)} mais barata',
      rotuloSuave: (vencedor) =>
          'Barato com arma de ${_nivelDeAtaqueDoVencedor(index, vencedor)}',
      busca: arma70,
      selo: (vencedor) => 'ARMA ${_nivelDeAtaqueDoVencedor(index, vencedor)}',
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
      index,
      carregadores,
      rotuloCheio: (_) => 'Atq lvl UP5 mais barato',
      rotuloSuave: (_) => 'Barato com Atq lvl UP5',
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
      index,
      carregadores,
      rotuloCheio: (_) => 'Def lvl UP5 mais barato',
      rotuloSuave: (_) => 'Barato com Def lvl UP5',
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
    index,
    todosPorPrecoDesc,
    rotuloCheio: (_) => 'O mais caro',
    rotuloSuave: (_) => 'Um dos mais caros',
    busca: buscaDoMaisCaro,
    nota: (vencedor, _) {
      // Conditional and derived: a wrong claim about the market's own top
      // would be a sentence tomorrow's collection could contradict.
      final nivel = _nivelDeAtaqueDoVencedor(index, vencedor);
      return nivel >= 70 ? 'O topo do mercado' : 'E não é o mais forte';
    },
  );

  // 6. Mais relíquias — a soma das três, e a troca é do dono em 01/10/2026.
  //
  // A carta era *Mais Chaves da Sorte* e saiu com a frase dele: *"estas são
  // as importantes, as chave da sorte não"*. A medição concorda e por um
  // motivo mais forte que o enunciado. Sobre os 1.666 de 01/10: a soma das
  // três está em **1.653 (99%)**, mediana 74, topo 595 — uma escala contínua
  // onde quase toda a gente está, e por isso ordena o mercado inteiro. A
  // Chave não é escala: 875 a carregam, metade dessas carrega exatamente
  // uma, e 655 das 875 vivem no primeiro 1,3% da sua faixa
  // (`counted_items.dart` diz o mesmo). Isso mede quem nunca gastou, não o
  // personagem.
  //
  // **E a porta fica mais simples do que a anterior.** A carta das chaves
  // precisava de um ranking feito à mão porque nenhuma `ResultOrder` sabe
  // ordenar por aquele item. Aqui `ResultOrder.mostOwned` **é** esta soma —
  // o comentário dela em `search_query.dart` diz que soma as três e exclui a
  // Chave de propósito. Então o destino abre ordenado pelo mesmo número que
  // o selo mostra, e o sujeito da carta é o primeiro resultado.
  //
  // Somar as três é legítimo e a regra já está escrita: atributos somam-se
  // *dentro* de um atributo, e as três relíquias são a mesma pergunta feita
  // de três maneiras — é o que `buscaInicial` já diz ao marcar as três de
  // uma vez. O que nunca se soma é um atributo a outro.
  final porReliquias = _carregadoresDeReliquias(index);
  _tentar(
    destaques,
    usadas,
    index,
    porReliquias,
    rotuloCheio: (_) => 'Mais relíquias',
    rotuloSuave: (_) => 'Muitas relíquias',
    busca: const SearchQuery(
      shownOwned: relicNames,
      order: ResultOrder.mostOwned,
    ),
    selo: (vencedor) => groupThousands(_somaDasReliquias(index, vencedor)),
    // A decomposição, e não só o total: um número que ninguém consegue
    // decompor é um número que ninguém consegue conferir — a mesma razão
    // pela qual `countedItemNotes` existe.
    nota: (vencedor, _) => [
      for (final nome in relicNames) '${index.countOf(vencedor, nome) ?? 0}',
    ].join(' + '),
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
///
/// The frame colour is never one of this function's own parameters: it is
/// always `weaponTierColor(index, candidato)`, read off whichever character
/// actually wins the category, so the colour is a fact about that person and
/// not a label the category hands out.
void _tentar(
  List<Destaque> destaques,
  Set<String> usadas,
  MarketIndex index,
  List<MarketCharacter> candidatos, {
  required String Function(MarketCharacter vencedor) rotuloCheio,
  required String Function(MarketCharacter vencedor) rotuloSuave,
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
        rotulo: empurrado ? rotuloSuave(candidato) : rotuloCheio(candidato),
        personagem: candidato,
        nota: nota(candidato, empurrado),
        cor: weaponTierColor(index, candidato),
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

/// The front page's argument for the 1.2.6 marketplace: two cards, never six.
///
/// **No domain knowledge, on purpose — the owner's own words, 01/10/2026:**
/// *"no momento a gente não sabe o que é importante no 1.2.6 para fazer novos
/// filtros"*. `destaquesDe` asks six questions this market has been studied
/// enough to pick — a weapon tier, a relic sum — and none of that study exists
/// for 1.2.6 yet. Six cards built the same way would be the site asserting a
/// ranking nobody asked for, which is exactly what the owner's four dropped
/// categories (most damage per TCC, highest damage, highest defence, highest
/// fire resistance) would have been.
///
/// Price needs no domain knowledge at all — every market answers it by
/// itself — so that is the whole list: the cheapest character, then the
/// dearest. Both read [MarketIndex] generically, so this same function would
/// work unchanged on the 1.8.7 index too; it is kept separate from
/// [destaquesDe] because the two questions sets answer different briefs, not
/// because the code could not be shared.
///
/// **The distinct-class rule still applies, and it bites harder here.** Six
/// classes stand behind this market instead of seventeen, so a collision is
/// six times likelier before either card is drawn — measured as one in six
/// against one in seventeen. The same softening [destaquesDe] already uses
/// (`_tentar`) covers it: the second card's label turns from *o mais caro* to
/// *um dos mais caros* the moment it has to cede the cheapest card's class.
///
/// Empty is an answer, same rule as [destaquesDe]: a market with nobody in it
/// draws no cards, never an exception.
List<Destaque> destaques126De(MarketIndex index) {
  final destaques = <Destaque>[];
  final usadas = <String>{};

  final maisBaratos = runQuery(index, const SearchQuery());
  _tentar(
    destaques,
    usadas,
    index,
    maisBaratos,
    rotuloCheio: (_) => 'O mais barato',
    rotuloSuave: (_) => 'Um dos mais baratos',
    busca: const SearchQuery(),
    nota: (_, _) =>
        '${groupThousands(index.characters.length)} personagens no mercado',
  );

  const buscaDoMaisCaro = SearchQuery(order: ResultOrder.dearest);
  final maisCaros = runQuery(index, buscaDoMaisCaro);
  _tentar(
    destaques,
    usadas,
    index,
    maisCaros,
    rotuloCheio: (_) => 'O mais caro',
    rotuloSuave: (_) => 'Um dos mais caros',
    busca: buscaDoMaisCaro,
    nota: (_, _) =>
        '${groupThousands(index.characters.length)} personagens no mercado',
  );

  return destaques;
}

/// Everyone carrying at least one of the three relics, most first.
///
/// Built here rather than taken from `ResultOrder.mostOwned` because the card
/// needs the ordered list *before* a query exists — but it is the same sum,
/// and `destaques_test` pins the two agreeing so they cannot drift.
///
/// Somebody carrying none of the three is not a carrier, the same call the
/// matcher makes for every `minimumOwned` filter.
List<MarketCharacter> _carregadoresDeReliquias(MarketIndex index) {
  if (!relicNames.any(index.countedItems.containsKey)) return const [];

  final comContagem = <(MarketCharacter, int)>[];
  for (final character in index.characters) {
    final total = _somaDasReliquias(index, character);
    if (total > 0) comContagem.add((character, total));
  }
  comContagem.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final par in comContagem) par.$1];
}

/// The three relics added together — one question asked three ways.
int _somaDasReliquias(MarketIndex index, MarketCharacter character) {
  var total = 0;
  for (final nome in relicNames) {
    total += index.countOf(character, nome) ?? 0;
  }
  return total;
}
