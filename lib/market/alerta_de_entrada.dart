import 'counted_items.dart';
import 'price_history.dart';

/// Which items are worth waking somebody up for, and how many of each.
///
/// **Named one by one, never by the filter's groups, and the market is why.**
/// Measured on 2026-10-02 over the 240 characters that had entered in the
/// previous day: 239 carried a *Relíquia Maravilha*, 233 carried something
/// under the *Essência Dracônica* label and 147 a *Chave da Sorte* — rules
/// that fire on everybody and so tell nobody anything. The same label's
/// *Bruta* alone fired on **two**. The grouping that makes the filter honest
/// would have made this feed useless, which is the whole reason this list
/// holds page names rather than `countedItemGroups` keys.
///
/// It may name **any item in the game**, not only the counted ones: the
/// collector's state keeps every character's whole inventory with its names,
/// so a name added here costs nothing but the next run — no rebuild, and
/// certainly no crawl.
///
/// The number is a floor, and it is what lets a common item earn a place:
/// *Chave da Sorte* at 1 fires on 147 a day and at 500 fires almost never.
///
/// **A name has to be exactly what the page prints.** A guessed one yields an
/// alert that never fires while looking like it works — the trap
/// `Cartão Gente Sortuda` already sprang, where *"Cartão de Gente Sortuda"*
/// would have cost the item in silence.
/// **Two spellings of the same card are listed on purpose.** The game uses
/// both shapes — `Cartão de Empolgação` has the preposition and
/// `Cartão Recompensa Cara Legal` does not, both read off real pages — and no
/// collection has ever resolved either *Cartão Gente* name, so which one this
/// server prints is genuinely unknown. A watched name that matches nobody
/// costs nothing, while guessing wrong costs the item in silence. Carrying
/// both and letting [nomesNuncaVistos] report it is cheaper than being right.
const vigiaDeItens = <String, int>{
  'Essência Dracônica Bruta': 1,
  'Baú Essência Dracônica': 1,
  'Cartão Recompensa Homem Nobre': 1,
  'Cartão Gente Boa': 1,
  'Cartão de Gente Boa': 1,
  'Cartão Gente Sortuda': 1,
  // **Common, so the floor is the whole entry.** Three of the four real pages
  // saved here carry one, at 10, 28 and 33 — at a floor of one this would
  // fire on nearly every arrival, which is the relics' defect. A hundred is
  // a provisional number and says so: the collector reports how many carry
  // each watched item and who carries most, so the next run replaces this
  // guess with a measurement rather than leaving it to taste.
  'Cupom Perfeito de Prata': 100,
};

/// Pets, which are watched by **id** and never by name.
///
/// **A pet's name belongs to its owner.** `38587` prints as *Ovo de Harpia*
/// on three characters and as *GabirÚ* on a fourth, and naming the pet is
/// exactly what somebody does when they get one — so a name watch would miss
/// precisely the people worth alerting about. The first run proved it:
/// `Ovo de Harpia` matched one carrier where the index counts several by id,
/// and `Ovo Mascote Gigante Celestial` matched nobody at all.
///
/// Presence and not quantity, the same call `countedItemIds` already makes
/// for the filter: a pet is a yes or a no, and there is no number to compare
/// between characters.
const vigiaDePets = countedItemIds;

/// Everybody carrying [item] right now, dearest stash first.
///
/// **The feed answers "who just arrived"; this answers "who has one".** They
/// are different questions and the first cannot be made to answer the second:
/// announcing the people already here would repeat them every half hour for
/// ever, which is why the trigger is a first sighting. This is the one-off
/// catch-up for an item that has just been put under watch, and it is
/// deliberately a manual run rather than something the schedule does.
List<EntradaNova> quemCarrega({
  required String item,
  required Iterable<AnuncioNoMercado> anuncios,
  required Map<int, Map<String, int>> inventarios,
}) {
  final portadores = <EntradaNova>[];
  for (final anuncio in anuncios) {
    final quantos = inventarios[anuncio.roleId]?[item] ?? 0;
    if (quantos <= 0) continue;
    portadores.add(
      EntradaNova(
        roleId: anuncio.roleId,
        nome: anuncio.nome,
        classe: anuncio.classe,
        nivel: anuncio.nivel,
        preco: anuncio.preco,
        achados: {item: quantos},
      ),
    );
  }
  portadores.sort((a, b) => b.achados[item]!.compareTo(a.achados[item]!));
  return portadores;
}

/// The watched names this collection never met in anybody's inventory.
///
/// **A guessed name is an alert that never fires while looking like it
/// works**, which is the worst failure this feed has: a quiet channel and a
/// misspelt item are the same thing from the outside. This is where the
/// difference gets said out loud, the same job the collector's line about
/// unresolved counted names already does.
///
/// It cannot distinguish a wrong spelling from an item nobody happens to be
/// carrying, and must not try: both are facts about one collection, and only
/// a name that stays missing run after run is evidence of a typo.
Set<String> nomesNuncaVistos(Iterable<Map<String, int>> inventarios) {
  final vistos = <String>{};
  for (final inventario in inventarios) {
    for (final nome in inventario.keys) {
      if (vigiaDeItens.containsKey(nome)) vistos.add(nome);
    }
  }
  return {
    for (final nome in vigiaDeItens.keys)
      if (!vistos.contains(nome)) nome,
  };
}

/// One character worth announcing, with what tripped the watch.
class EntradaNova {
  const EntradaNova({
    required this.roleId,
    required this.nome,
    required this.classe,
    required this.nivel,
    required this.preco,
    required this.achados,
  });

  final int roleId;
  final String nome;
  final String classe;
  final int nivel;
  final int preco;

  /// Item name to how many of it, for the watched items this character
  /// actually carries. Never empty — a character with nothing on the list is
  /// not an entry.
  final Map<String, int> achados;
}

/// How many entries in one collection stop being news and become a flood.
///
/// **This is a safety valve against our own state, not against the market.**
/// `firstSeen` is set to now for every character alive whenever the site has
/// no memory to carry forward — a lost CI cache, a first run, a published
/// index that failed to load. The market cannot produce 1.600 genuine
/// arrivals in half an hour; our own bookkeeping can, and did so on the day
/// the cache key changed. Past this count the feed says one line instead of
/// emptying the whole market into a channel nobody will read again.
const limiteDeEnxurrada = 50;

/// The characters whose first sighting is **this** collection and who carry
/// something on [vigiaDeItens].
///
/// `firstSeen` is the trigger rather than a record of what has been posted,
/// and that is deliberate: it never moves — not even when a character leaves
/// the market and comes back — so each one is announced exactly once with
/// nothing to store and nothing to drift.
///
/// [inventarios] is role id to the item names and counts that character owns.
/// [inventarios] is role id to the item **names** and counts that character
/// owns; [inventariosPorId] is the same inventory keyed by item id, which is
/// what [vigiaDePets] needs.
List<EntradaNova> entradasParaAvisar({
  required Iterable<AnuncioNoMercado> anuncios,
  required Map<int, Map<String, int>> inventarios,
  required Map<int, PriceHistory> memoria,
  required DateTime agora,
  Map<int, Map<int, int>> inventariosPorId = const {},
}) {
  final entradas = <EntradaNova>[];

  for (final anuncio in anuncios) {
    if (memoria[anuncio.roleId]?.firstSeen != agora) continue;

    final achados = <String, int>{};
    final inventario = inventarios[anuncio.roleId] ?? const {};
    for (final entry in vigiaDeItens.entries) {
      final quantos = inventario[entry.key] ?? 0;
      if (quantos >= entry.value) achados[entry.key] = quantos;
    }
    final porId = inventariosPorId[anuncio.roleId] ?? const {};
    for (final entry in vigiaDePets.entries) {
      final quantos = porId[entry.value] ?? 0;
      if (quantos > 0) achados[entry.key] = quantos;
    }

    if (achados.isEmpty) continue;

    entradas.add(
      EntradaNova(
        roleId: anuncio.roleId,
        nome: anuncio.nome,
        classe: anuncio.classe,
        nivel: anuncio.nivel,
        preco: anuncio.preco,
        achados: achados,
      ),
    );
  }

  return entradas;
}

/// The handful of listing fields an alert needs, so this file depends on the
/// listing's shape and not on the collector that parses it.
class AnuncioNoMercado {
  const AnuncioNoMercado({
    required this.roleId,
    required this.nome,
    required this.classe,
    required this.nivel,
    required this.preco,
  });

  final int roleId;
  final String nome;
  final String classe;
  final int nivel;
  final int preco;
}
