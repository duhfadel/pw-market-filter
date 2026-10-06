import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'atributos_126.dart';
import 'detail_parser.dart' show ParsedItem, parseSex;

final _slotPattern = RegExp(r'slot-(\d+)');
final _gradePattern = RegExp(r'grade-(\d+)');
final _itemIdPattern = RegExp(r'/(\d+)\.png');

/// Reads the items a character is wearing, out of a 1.2.6 detail page.
///
/// The page carries equipment in two places, and the relationship is the
/// *same shape* as 1.8.7's but not the same mechanism. The paper doll
/// (`ul.character-equip--list`) is the only place that says what is worn —
/// confirmed on both fixtures, 11 slots each. The **first** tab of the
/// inventory panel, labelled `Equipamento` (`.v-window-item.inventory
/// ul.list-item`, taken in document order, before `Inventário` and
/// `Banqueiro`), lists more than what is worn: 21 entries against 11 worn on
/// both fixtures, the extra ten being fashion pieces and switched-out
/// equipment with no stat JSON (`data-item='null'`).
///
/// Unlike 1.8.7, there is no tooltip and no numeric id to join stats by — and
/// joining by item id would be wrong here anyway: a character can wear two
/// rings of the same item id with **different rolls** (measured on
/// `detail_pw126_5424.html`, item `6175`, one copy giving 81 defence and the
/// other 60). What *is* reliable, measured on both fixtures: the
/// `Equipamento` tab's entries are in the **same order** as the paper doll
/// for exactly as many positions as are worn, id for id. So the two lists are
/// paired by position, not by id — id equality is still checked per pair as a
/// guard, and a mismatch drops that item's attributes rather than attaching
/// the wrong ones.
///
/// `data-item` is single-quoted in 1.2.6, with its own quotes escaped as
/// `&quot;` — reading it through `Element.attributes`, as this does, decodes
/// that transparently; the trap is only real for a hand-written regex that
/// assumes double quotes, which matches zero and reports success on nothing.
List<ParsedItem> parseEquippedItems126(String html) {
  final document = html_parser.parse(html);

  final dollElements = document.querySelectorAll(
    'ul.character-equip--list > li',
  );
  final tabElements =
      document
          .querySelector('.v-window-item.inventory ul.list-item')
          ?.querySelectorAll('li[data-item]') ??
      const <Element>[];

  final items = <ParsedItem>[];
  for (var i = 0; i < dollElements.length; i++) {
    final worn = _readDollItem(dollElements[i]);
    if (worn == null) continue;

    final decoded = i < tabElements.length
        ? _decodedFor(tabElements[i], worn.itemId)
        : null;

    items.add(decoded == null ? worn : _withStats(worn, decoded));
  }
  return items;
}

/// `Masculino` or `Feminino`, empty when the page does not say.
///
/// Delegates straight to [parseSex] — both versions' character sheets share
/// the exact `.character-info--list` / `.skill-desc` / `.value` shape,
/// confirmed on both 1.2.6 fixtures. Kept as its own name, rather than wiring
/// `Servidor.sexo` to [parseSex] for both versions, so the day the sheets
/// diverge there is one place to change and not every call site that reads a
/// character's sex.
String parseSex126(String html) => parseSex(html);

/// The character's class, read off the header badge (`li.classname span`).
/// Null when the page does not carry it.
String? parseClasse126(String html) {
  final text = html_parser
      .parse(html)
      .querySelector('li.classname span')
      ?.text
      .trim();
  return (text == null || text.isEmpty) ? null : text;
}

ParsedItem? _readDollItem(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final enchance = element.querySelector('.item-enchance')?.text.trim() ?? '';

  return ParsedItem(
    slot: _firstNumber(_slotPattern, element.attributes['data-item-type']),
    itemId: _firstNumber(_itemIdPattern, image.attributes['src']),
    grade: _firstNumber(_gradePattern, element.attributes['data-item-grade']),
    name: (image.attributes['data-item-name'] ?? '').trim(),
    refine: int.tryParse(enchance.replaceFirst('+', '')) ?? 0,
    stones: const [],
    attributes: const {},
  );
}

/// The decoded `data-item` JSON of one `Equipamento`-tab entry, or null when
/// it carries no stats (`data-item='null'`, the fashion/spare tail of the
/// tab) or when its item id does not match the worn piece at the same
/// position — the guard against the positional pairing being wrong.
Map<String, dynamic>? _decodedFor(Element tabElement, int expectedItemId) {
  final actualId = _firstNumber(
    _itemIdPattern,
    tabElement.querySelector('img')?.attributes['src'],
  );
  if (actualId != expectedItemId) return null;

  final raw = tabElement.attributes['data-item'];
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

ParsedItem _withStats(ParsedItem worn, Map<String, dynamic> decoded) =>
    ParsedItem(
      slot: worn.slot,
      itemId: worn.itemId,
      grade: worn.grade,
      name: worn.name,
      refine: worn.refine,
      stones: _stonesFrom(decoded),
      attributes: _translateAttributes(decoded),
      requireLevel: _intOf(decoded['require_level']),
      weaponLevel: _intOf(decoded['weapon_level']),
    );

/// Every column named in [atributos126], carried over when the item actually
/// grants it. A zero in these columns means the same thing an absent tooltip
/// line means in 1.8.7 — the item does not touch that attribute — so it is
/// skipped rather than printed as a false `+0`.
Map<String, List<int>> _translateAttributes(Map<String, dynamic> decoded) {
  final attributes = <String, List<int>>{};
  for (final entry in atributos126.entries) {
    final value = decoded[entry.key];
    if (value is num && value != 0) {
      attributes[entry.value] = [value.round()];
    }
  }
  return attributes;
}

/// The socketed stones, straight off `slots.slotStones` — an empty socket is
/// `0` in this JSON, and is filtered out the same way a missing stone image
/// is simply absent in 1.8.7's tooltip.
List<int> _stonesFrom(Map<String, dynamic> decoded) {
  final slots = decoded['slots'];
  if (slots is! Map) return const [];
  final stones = slots['slotStones'];
  if (stones is! List) return const [];
  return stones
      .whereType<num>()
      .map((stone) => stone.toInt())
      .where((stone) => stone != 0)
      .toList(growable: false);
}

int _intOf(Object? value) => value is num ? value.toInt() : 0;

int _firstNumber(RegExp pattern, String? source) {
  if (source == null) return 0;
  final match = pattern.firstMatch(source);
  return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
}

/// How many of each store a character is using, and how big that store is.
///
/// The 1.2.6 page has a section the 1.8.7 one does not — `Itens do
/// Personagem` — with five tabs, four of which print `usados / capacidade`.
///
/// **The capacity is the fact worth having, and it is the second number.**
/// Measured over nine real pages: the bag runs 32, 40, 48 and 64, and the
/// materials store runs 0, 16, 48 and 96. Expanding costs money in the game,
/// so the capacity says something about the character while the occupancy
/// says what the seller happened to leave inside.
class EspacoDeItens {
  const EspacoDeItens({required this.usados, required this.capacidade});

  final int usados;

  /// Zero where the character has never opened that store at all — four of
  /// the nine measured had `0/0` in both Roupas and Materiais. Zero is a
  /// real answer there, not a missing one.
  final int capacidade;
}

/// The five tabs, by the label the page prints.
///
/// `Equipamento` has no capacity — it is a count of worn pieces, not a store —
/// so it is read with a capacity of zero and kept anyway: it costs nothing and
/// it is the only one of the five this collector would otherwise have to
/// compute for itself.
Map<String, EspacoDeItens> parseEspacos126(String html) {
  final espacos = <String, EspacoDeItens>{};

  for (final aba
      in html_parser
          .parse(html)
          .querySelectorAll('.character-inventory .v-tab span')) {
    final em = aba.querySelector('em');
    if (em == null) continue;

    final rotulo = aba.nodes
        .whereType<Text>()
        .map((t) => t.text.trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');
    if (rotulo.isEmpty) continue;

    // The occupancy is `em`'s own text, before the two `<b>` children that
    // carry the slash and the capacity. Reading `em.text` whole would glue
    // the three together into `27/64` and then into 2764.
    final usados = int.tryParse(
      em.nodes.whereType<Text>().map((t) => t.text.trim()).join(),
    );
    if (usados == null) continue;

    final capacidade = int.tryParse(
      aba.querySelectorAll('em > b').last.text.trim(),
    );
    espacos[rotulo] = EspacoDeItens(
      usados: usados,
      capacidade: capacidade ?? 0,
    );
  }

  return espacos;
}

/// A pet or a mount the character owns.
class MascoteDoPersonagem {
  const MascoteDoPersonagem({
    required this.nome,
    required this.montaria,
    required this.nivel,
  });

  /// As the page prints it — `Ovo de Hércules`. **This version names the
  /// species where 1.8.7 lets the owner rename the egg**, which is why the
  /// filter there has to go by item id and this one can go by name. Worth
  /// knowing before copying either rule onto the other.
  final String nome;

  /// `data-character-mount`: a mount rather than a combat pet.
  final bool montaria;

  final int nivel;
}

/// Every pet and mount in the character's cage.
///
/// Kept whole even though only one of them is filtered on today: the owner
/// asked for the Hércules and for the rest to be mapped anyway, and a crawl
/// that is already paid for should take everything the page offers.
List<MascoteDoPersonagem> parseMascotes126(String html) {
  final mascotes = <MascoteDoPersonagem>[];

  for (final badge
      in html_parser.parse(html).querySelectorAll('[data-pet-name]')) {
    final nome = badge.attributes['data-pet-name']?.trim() ?? '';
    if (nome.isEmpty) continue;

    var nivel = 0;
    final tooltip = badge.attributes['data-pet-tooltip'];
    if (tooltip != null) {
      try {
        final json = jsonDecode(tooltip);
        if (json is Map && json['pet_level'] is int) {
          nivel = json['pet_level'] as int;
        }
      } on FormatException {
        // A tooltip this reader cannot decode costs the level and nothing
        // else — the name is on the element itself.
      }
    }

    mascotes.add(
      MascoteDoPersonagem(
        nome: nome,
        montaria: badge.attributes['data-character-mount'] == '1',
        nivel: nivel,
      ),
    );
  }

  return mascotes;
}

/// Os quatro ofícios de artesanato, pelos ids com que a página os publica.
///
/// **Em ordem de id e nunca de nome.** O dono diz que se chamam *forja de
/// arma, armadura, acessórios e boticário*, e a tentação é atribuí-los por
/// essa ordem — mas nada na página o confirma, e um rótulo errado é pior do
/// que número nenhum: quem procurasse o ferreiro escolheria o boticário e
/// nunca saberia. A tela mostra os quatro valores sem dizer qual é qual, do
/// mesmo modo que um atributo sem nome é impresso como `#3818`.
///
/// Os ids saíram do cruzamento das perícias de quatro personagens de quatro
/// classes: cinco ids sobrevivem a essa interseção, quatro deles
/// consecutivos e todos entre 7 e 8 num nível 102. O quinto, 167, é 1 em
/// toda a gente.
///
/// **O máximo é pelo menos 8**, medido em `detail_pw126_62224.html`, que dá
/// `[7, 7, 7, 8]` — contra os 7 que se supunham. E não é toda a gente que os
/// tem: duas das três fixtures não trazem nenhum dos quatro.
const idsDaForja = [158, 159, 160, 161];

/// Every skill the page lists, as id to level.
///
/// **No names anywhere on the page**, which is the whole difficulty: the four
/// crafting skills the 1.2.6 players asked about are ids 158, 159, 160 and
/// 161, found by intersecting the skills of four characters of four different
/// classes — five ids survive that intersection, four of them consecutive and
/// all four sitting at 7 or 8 on a level-102 character. The fifth, 167, is 1
/// on everybody.
///
/// Which of the four is the weapon forge and which the apothecary cannot be
/// read off the page, so nothing here guesses: the levels are stored by id
/// and named only once somebody reads them in the game. Storing them raw is
/// what makes that naming a rebuild instead of another crawl.
Map<int, int> parsePericias126(String html) {
  final pericias = <int, int>{};
  for (final badge
      in html_parser
          .parse(html)
          .querySelectorAll('[data-skill-id][data-skill-level]')) {
    final id = int.tryParse(badge.attributes['data-skill-id'] ?? '');
    if (id == null) continue;
    pericias[id] =
        int.tryParse(badge.attributes['data-skill-level'] ?? '') ?? 0;
  }
  return pericias;
}
