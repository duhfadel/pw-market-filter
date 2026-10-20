import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../market/romanos.dart';

/// One item the character is actually wearing.
///
/// Attributes are keyed by the name the site prints — including the
/// `Atributo #3818` it falls back to when it cannot name one itself. There is
/// no numeric attribute id here on purpose; see [parseEquippedItems].
///
/// Each attribute maps to **every occurrence**, in the order the tooltip lists
/// them, rather than to one reduced number. How to reduce them is a question
/// about the game, not about HTML — three `HP` lines add up to a total, while
/// `Nível de Ataque +70` followed by `+1` is a principal and a minor bonus, and
/// the weapon is a 70. Reducing here would bake one of those answers into the
/// reader and, worse, make correcting it cost a fresh collection of all 771
/// pages. [IndexBuilder] applies the rules; this only reports what was on the
/// page.
class ParsedItem {
  const ParsedItem({
    required this.slot,
    required this.itemId,
    required this.grade,
    required this.name,
    required this.refine,
    required this.stones,
    required this.attributes,
    this.requireLevel = 0,
    this.weaponLevel = 0,
    this.nivel = 0,
  });

  ParsedItem withLevels({required int require, required int weapon}) =>
      ParsedItem(
        slot: slot,
        itemId: itemId,
        grade: grade,
        name: name,
        refine: refine,
        stones: stones,
        attributes: attributes,
        requireLevel: require,
        weaponLevel: weapon,
        nivel: nivel,
      );

  final int slot;
  final int itemId;
  final int grade;
  final String name;
  final int refine;
  final List<int> stones;

  /// O nível do astrolábio ou do conduíte; zero em tudo o resto.
  ///
  /// **Contexto, nunca medida.** Três personagens medidos a 20/10/2026, todos
  /// com o conduíte no nível 100, deram `Nv. de Ataque` +32, +32 e +26 — o
  /// nível é o tecto que o jogador pode subir, e os atributos são o que ele
  /// subiu. Quem ler este campo como força publica um número errado com cara
  /// de certo.
  final int nivel;
  final Map<String, List<int>> attributes;

  /// The level the piece demands — 60, 80, 100 or 105. Zero when unknown.
  ///
  /// This one does come from the inventory panel's JSON, joined by item id.
  /// The join is safe because no character wears two copies of the same item
  /// id, checked across the fixture; and it is worth the exception because the
  /// paper doll's tooltip does not carry it at all.
  final int requireLevel;

  /// The `weapon_level` of the same JSON, and **not** a quality rank: it is 17
  /// for every common endgame weapon, including one that gives no attack level
  /// at all. Read because the page is already open — a second crawl of the
  /// market costs fifty minutes — and kept raw in the collector's state until
  /// something turns out to want it. Zero on anything that is not a weapon.
  final int weaponLevel;
}

/// One of the six War Avatar cards a character has equipped.
///
/// Six exactly, one per [type] — Destruidor, Batalha, Durabilidade, Alma
/// Primordial, Vida Primordial, Longevidade. A "combo" is those six belonging
/// to the same named set.
class ParsedCard {
  const ParsedCard({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.type,
    required this.level,
    required this.maxLevel,
  });

  final int cardId;
  final String name;

  /// `S`, `A` or `B`, and the cap moves with it: 80, 40, 25.
  final String rarity;

  final String type;

  /// Owning a card and having it finished are different things, and the price
  /// knows the difference: one character had ten S cards, nine of them at 1/80.
  final int level;
  final int maxLevel;
}

final _slotPattern = RegExp(r'slot-(\d+)');
final _gradePattern = RegExp(r'grade-(\d+)');
final _itemIdPattern = RegExp(r'/(\d+)\.png');
final _titlePattern = RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true);
final _refinePattern = RegExp(r'\s\+(\d+)$');
// A stone is the only image inside a tooltip, and it is always 16 px wide.
final _stonePattern = RegExp(
  r'<img[^>]+src="[^"]*?/(\d+)\.png"[^>]*?width="16"',
);
// One bonus line: `➜ Nível de Ataque +70`, ending at the closing tag. Keeping
// the value anchored to the end of the text node stops a `+` inside a name
// from being read as the value.
final _attributePattern = RegExp(r'➜\s*([^<]*?)\s*([+-]\d+)\s*(?=<|$)');

/// O bónus de um astrolábio, de um conduíte ou de um livro divino: uma linha
/// inteira dentro de um `<span>`, **sem seta nenhuma**.
///
/// **Três slots que o parser via vazios, e era por isto.** Medido a
/// 20/10/2026 sobre o 1.8.7: 2.193 astrolábios, 1.998 conduítes e 1.726
/// livros divinos no índice, todos com zero atributos, contra 2.193 de 2.193
/// na armadura. Os dados estavam na página desde sempre; só não usam `➜`.
///
/// A cor é parte da gramática e não decoração — ver [_corGanha].
final _spanBonusPattern = RegExp(
  r'<span[^>]*?color:\s*([^;"]+)[^>]*>([^<]*?)\s*([+-][\d.]+)\s*%?\s*</span>',
);

/// O prefixo de ramo do astrolábio: `Destino · Atq Físico +497`.
///
/// **Tirado do nome, e isso é decisão e não descuido.** `Destino` e `Guia`
/// são os dois ramos de onde o bónus vem, não dois atributos diferentes — um
/// personagem com `Destino · Espírito +155` e `Guia · Espírito +83` tem 238
/// de espírito, e guardar dois nomes diferentes dividiria em duas colunas uma
/// coisa que o jogador soma. A regra `total` de `attributeRules` faz o resto.
final _ramoPattern = RegExp(r'^(?:Destino|Guia)\s*·\s*');

/// A escada de refino do livro divino: `(+3) : Atq Físico +50`.
///
/// O livro imprime **todos** os patamares, inclusive os que o personagem
/// ainda não alcançou, e só a cor os separa. O número entre parênteses é o
/// refino que o patamar exige.
final _escadaPattern = RegExp(r'^\(\+(\d+)\)\s*:\s*');

/// O nível do item, quando ele tem um: `Nível 49` num astrolábio, `Nível do
/// Conduíte 60` num conduíte.
///
/// **Não é a medida da força, e confundir as duas coisas seria publicar um
/// número errado com cara de certo** — correcção do dono em 20/10/2026, que a
/// página confirma. Cada nível dá atributos para o jogador subir um a um, e o
/// nível de ataque sobe 1, 2, 4 … até 32. Três personagens medidos **todos no
/// nível 100** deram +32/+32, +32/+32 e +26/+6. O nível é tecto; os
/// atributos são o que o personagem tem.
final _nivelPattern = RegExp(r'Nível(?: do Conduíte)? (\d+)<');

/// O site a dizer que não sabe: `Atributos do Conduíte não resolvidos.`
///
/// Terceiro estado, distinto de "não tem bónus nenhum". Visto num conduíte de
/// nível 2; sem isto o índice afirmaria um zero que ninguém verificou.
final _naoResolvido = RegExp(r'não resolvid');

/// Reads the items a character is wearing, out of a detail page.
///
/// The page carries equipment twice and only one copy is usable. The inventory
/// panel's `Equipamento` section has richer JSON but **no slot number**, and it
/// lists spares too — 31 entries against the 14 that are worn. The paper doll
/// (`ul.character-equip--list`) is the only place that says what is on the
/// character, so it is the one parsed here.
///
/// Its tooltip carries everything needed: name, refine, socket stones and the
/// bonus lines. The JSON's numeric addon ids are deliberately not joined in —
/// the two lists cannot be zipped, because the JSON also counts the refine
/// bonus and the socket stones as addons (14 entries against the tooltip's 11)
/// and the extras sit in the middle, not at the end.
List<ParsedItem> parseEquippedItems(String html) {
  final document = html_parser.parse(html);
  final levels = _levelsById(document);

  return document
      .querySelectorAll('ul.character-equip--list > li')
      .map(_readItem)
      .whereType<ParsedItem>()
      .map((item) {
        final level = levels[item.itemId];
        return level == null
            ? item
            : item.withLevels(require: level.require, weapon: level.weapon);
      })
      .toList(growable: false);
}

/// The two levels the inventory panel's JSON carries, per item id.
///
/// The only thing taken from that panel for a worn piece. It has no slot
/// numbers and lists spares, so it cannot say what is worn — but it does carry
/// `require_level` and `weapon_level`, which the paper doll's tooltip never
/// mentions.
Map<int, ({int require, int weapon})> _levelsById(Document document) {
  final levels = <int, ({int require, int weapon})>{};

  for (final json in _inventoryJson(document)) {
    final id = json['id'];
    final decoded = json['decoded'] as Map<String, dynamic>?;
    final require = decoded?['require_level'];
    final weapon = decoded?['weapon_level'];
    if (id is! int) continue;
    levels[id] = (
      require: require is int ? require : 0,
      weapon: weapon is int ? weapon : 0,
    );
  }
  return levels;
}

/// Every `data-item` on the page, decoded. One unreadable entry is skipped
/// rather than costing the whole page.
Iterable<Map<String, dynamic>> _inventoryJson(Document document) sync* {
  for (final element in document.querySelectorAll('li[data-item]')) {
    final raw = element.attributes['data-item'];
    if (raw == null) continue;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) yield json;
    } on FormatException {
      continue;
    }
  }
}

/// How far a character has got through the game's anecdotes.
///
/// The pair is printed as one string — `1265/2756` — and the two halves mean
/// different things: [done] is the character's, [total] is the game's.
class ParsedAnecdotes {
  const ParsedAnecdotes({
    required this.done,
    required this.total,
    required this.lines,
  });

  final int done;
  final int total;

  /// How many anecdote lines the character has met at all. Read because it is
  /// beside the pair and free; nothing filters on it yet.
  final int lines;
}

final _anecdoteProgressPattern = RegExp(r'(\d+)\s*/\s*(\d+)');

/// Null when the page has no anecdote panel.
///
/// Null and not `0/0`: zero of zero would read as a character who has
/// completed nothing, and that is a claim. A page that does not say says
/// nothing.
ParsedAnecdotes? parseAnecdotes(String html) {
  final document = html_parser.parse(html);
  final summary = document.querySelector('.pw187-anecdote-summary');
  if (summary == null) return null;

  var done = 0;
  var total = 0;
  var lines = 0;
  var found = false;

  for (final row in summary.querySelectorAll('li')) {
    final label = row.querySelector('span')?.text.trim() ?? '';
    final value = row.querySelector('strong')?.text.trim() ?? '';

    if (label == 'Progresso total') {
      final match = _anecdoteProgressPattern.firstMatch(value);
      if (match == null) continue;
      done = int.parse(match.group(1)!);
      total = int.parse(match.group(2)!);
      found = true;
    } else if (label == 'Linhas') {
      lines = int.tryParse(value) ?? 0;
    }
  }

  return found ? ParsedAnecdotes(done: done, total: total, lines: lines) : null;
}

/// One stack of one item the character owns, wherever it is kept.
class ParsedStack {
  const ParsedStack({
    required this.itemId,
    required this.name,
    required this.count,
  });

  final int itemId;
  final String name;

  /// Every copy the character holds, added across bag, bank and the rest.
  final int count;
}

/// Everything the character owns, by item id.
///
/// This is the inventory JSON `CLAUDE.md` warns against — and counting is the
/// one job it is right for. The warning is about *worn* equipment, where the
/// panel carries no slot number and lists spares beside the real piece; the
/// paper doll stays the only source for that. Here the spares are the point.
///
/// Ids repeat across the subpanels — a stack in the bag and another in the
/// bank — so they are summed. The name is the first one seen, which is the
/// same item's name every time.
List<ParsedStack> parseInventory(String html) {
  final document = html_parser.parse(html);
  final counts = <int, int>{};
  final names = <int, String>{};

  for (final json in _inventoryJson(document)) {
    final id = json['id'];
    if (id is! int) continue;
    final count = json['count'];
    counts[id] = (counts[id] ?? 0) + (count is int ? count : 0);
    final name = json['item_name'] ?? json['name'];
    if (name is String) names.putIfAbsent(id, () => name);
  }

  return [
    for (final entry in counts.entries)
      ParsedStack(
        itemId: entry.key,
        name: names[entry.key] ?? '',
        count: entry.value,
      ),
  ];
}

final _rarityPattern = RegExp(r'Nível ([SAB])<br>');
final _cardTypePattern = RegExp(r'Tipo ([^<]+?)<br>');
final _cardLevelPattern = RegExp(r'Nível (\d+)/(\d+)');

/// The six cards the character has equipped.
///
/// Same trap as the equipment, same answer. The inventory has a `cards` panel
/// holding the whole collection — 35 cards on one character, 60 on another —
/// and that is not what is worn. `<h4>Cartas equipadas</h4>` is, and it always
/// holds exactly six.
List<ParsedCard> parseEquippedCards(String html) {
  final document = html_parser.parse(html);

  return document
      .querySelectorAll('.pw187-detail-equipped-cards .pw187-detail-card-slot')
      .map(_readCard)
      .whereType<ParsedCard>()
      .toList(growable: false);
}

ParsedCard? _readCard(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final tooltip = image.attributes['data-pw187-tooltip'] ?? '';
  final progress = _cardLevelPattern.firstMatch(tooltip);

  return ParsedCard(
    cardId: _firstNumber(_itemIdPattern, image.attributes['src']),
    name: (image.attributes['alt'] ?? '').trim(),
    rarity: _rarityPattern.firstMatch(tooltip)?.group(1) ?? '',
    type: _cardTypePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '',
    level: int.tryParse(progress?.group(1) ?? '') ?? 0,
    maxLevel: int.tryParse(progress?.group(2) ?? '') ?? 0,
  );
}

/// One of the two paths the character committed to, or null when the page
/// does not say.
///
/// Read off the name of a skill, which is the player's own test: **Evil has
/// `Erupção Demoníaca`, God has `Erupção Celestial`**. There is no field for
/// it anywhere on the sheet — `Sagrado` and `Demoníaco` appear only as item
/// names — so it has to be derived, and this is the most legible way to derive
/// it: a word the game prints on screen.
///
/// The page carries a second, redundant signal: the path's skills are prefixed
/// `●`/`Φ` for God and `○`/`Ω` for Evil, and the God ones also carry the CSS
/// class `pw187-skill-slot--sage`. Across fifteen pages the symbol and the
/// eruption agreed every time, and `sheet_test` pins the eruption because a
/// name the game shows outlives a class name a redesign can rewrite.
///
/// Null and not a guess: a character too low to have the skill has no path
/// yet, and calling him God by omission would put half the market on the wrong
/// side of a filter.
String? parsePath(String html) {
  // Through the parser, never over the raw bytes: the page writes the name as
  // `Erup&ccedil;&atilde;o Demon&iacute;aca`, so a plain `contains` on the
  // source finds nothing and reports every character as pathless.
  for (final slot in html_parser.parse(html).querySelectorAll('[aria-label]')) {
    final label = slot.attributes['aria-label'] ?? '';
    if (label.contains('Erupção Demoníaca')) return 'Evil';
    if (label.contains('Erupção Celestial')) return 'God';
  }
  return null;
}

/// The `Reino Celestial` row of the character sheet, exactly as the site
/// writes it — `Céu Ápice VIII`.
///
/// Kept raw rather than reduced to a number here, for the reason the whole
/// collector works this way: the ordering is a fact about the game, not about
/// HTML, and a wrong order corrected later would otherwise cost a fresh crawl.
/// `CelestialRealm` turns the string into a position.
String? parseCelestialRealm(String html) =>
    _sheetValue(html_parser.parse(html), 'Reino Celestial');

/// `Masculino` or `Feminino`, empty when the page does not say.
///
/// It cannot be derived from the class: Perfect World locks most classes to a
/// gender and this server mostly follows, but Bardo has both — which is why
/// this has to be read per character.
String parseSex(String html) =>
    _sheetValue(html_parser.parse(html), 'Sexo') ?? '';

/// One labelled row of the character sheet — the short list that carries
/// `Classe`, `Sexo` and `Reino Celestial` and nothing else.
String? _sheetValue(Document document, String label) {
  for (final row in document.querySelectorAll('.character-info--list')) {
    if (row.querySelector('.skill-desc')?.text.trim() != label) continue;
    return row.querySelector('.value')?.text.trim();
  }
  return null;
}

/// One rune, and the skill it was set on.
///
/// The pair is the unit the page draws and the unit the game thinks in: a rune
/// does nothing on its own, it empowers a skill.
class ParsedRune {
  const ParsedRune({
    required this.slot,
    required this.itemId,
    required this.type,
    required this.level,
    required this.skillId,
    required this.skillName,
  });

  final int slot;
  final int itemId;

  /// `Argêntea`, `Áurea`, `Celeste`, `Escarlate`, `Verdejante` — a category,
  /// not a grade: every colour was seen from level 4 to 9.
  final String type;

  final int level;
  final int skillId;
  final String skillName;
}

// `Runa Áurea Nv. 6 · Slot 3` and `Runa Celeste Nível 8 · Slot 3` both occur,
// on the same page. Reading only `Nv.` silently drops every level 8 — which is
// exactly the band anybody filtering on runes cares about.
final _runeLabelPattern = RegExp(r'Runa\s+(\S+)\s+(?:Nv\.|Nível)\s+(\d+)');

/// The runes the character has set, one per slot, in slot order.
///
/// Six slots is the common case and nine exists; the count is read from the
/// page rather than assumed. A character with none has the section drawn and
/// empty, which is not an error and not an absence of the section.
List<ParsedRune> parseRunes(String html) {
  final document = html_parser.parse(html);
  final runes = <ParsedRune>[];

  for (final pair in document.querySelectorAll('.pw187-rune-pair')) {
    final slot = int.tryParse(pair.attributes['data-rune-slot'] ?? '');
    final rune = pair.querySelector('.pw187-rune-pair__rune');
    final skill = pair.querySelector('.pw187-rune-pair__skill');
    if (slot == null || rune == null) continue;

    final match = _runeLabelPattern.firstMatch(
      rune.attributes['aria-label'] ?? '',
    );
    if (match == null) continue;

    final tooltip = skill?.attributes['data-pw187-skill-tooltip'] ?? '';
    runes.add(
      ParsedRune(
        slot: slot,
        itemId: int.tryParse(rune.attributes['data-item-id'] ?? '') ?? 0,
        type: match.group(1)!,
        level: int.parse(match.group(2)!),
        skillId: int.tryParse(skill?.attributes['data-skill-id'] ?? '') ?? 0,
        skillName: _titlePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '',
      ),
    );
  }

  runes.sort((a, b) => a.slot.compareTo(b.slot));
  return runes;
}

ParsedItem? _readItem(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final tooltip = image.attributes['data-pw187-tooltip'] ?? '';
  final title = _titlePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '';
  // Falling back to the image's alt keeps an item with a broken tooltip in the
  // index under its name, rather than dropping it silently.
  final name = title.isEmpty ? (image.attributes['alt'] ?? '').trim() : title;

  return ParsedItem(
    slot: _firstNumber(_slotPattern, element.attributes['data-item-type']),
    itemId: _firstNumber(_itemIdPattern, image.attributes['src']),
    grade: _firstNumber(_gradePattern, element.attributes['data-item-grade']),
    name: name.replaceFirst(_refinePattern, ''),
    refine: _firstNumber(_refinePattern, name),
    stones: _stonePattern
        .allMatches(tooltip)
        .map((m) => int.parse(m.group(1)!))
        .toList(growable: false),
    attributes: _readAttributes(tooltip),
    nivel: _lerNivel(tooltip),
  );
}

/// A single item can carry the same bonus more than once — the weapon in the
/// fixture lists `HP +500`, `HP +150`, `HP +150`. Every occurrence is kept, in
/// order; overwriting on collision would report 150 where the item gives 800,
/// and summing here would report 71 for a weapon whose principal is 70.
Map<String, List<int>> _readAttributes(String tooltip) {
  final attributes = <String, List<int>>{};

  for (final match in _attributePattern.allMatches(tooltip)) {
    final name = match.group(1)!.trim();
    if (name.isEmpty) continue;
    final value = int.tryParse(match.group(2)!);
    if (value == null) continue;
    (attributes[name] ??= <int>[]).add(value);
  }

  _lerBonusDeSpan(tooltip, attributes);
  return attributes;
}

/// As três cores que marcam um bónus que o personagem **já tem**.
///
/// **A cor é a gramática, e ignorá-la daria a um livro +12 os bónus de um
/// +15.** A escada de refino imprime todos os patamares; o que foi ganho vem
/// a verde (`#6cff6c`), o que falta vem a cinzento (`#a7a7a7`). As outras
/// duas são os bónus normais do astrolábio e do conduíte, que só existem na
/// lista quando existem de facto — vermelho para o ramo `Destino`, azul para
/// `Guia` e para as linhas do conduíte.
///
/// Uma cor desconhecida **conta**, de propósito: um patamar por ganhar é o
/// único caso provado de linha que não vale, e apanha-se pelo cinzento. Se o
/// site inventar uma quarta cor para um bónus real, incluí-la erra para o
/// lado de mostrar a mais, que é recuperável; excluí-la apagaria em silêncio
/// um atributo que o personagem tem.
const _cinzentoDoNaoGanho = 'a7a7a7';

/// Os bónus que vêm em `<span>` em vez de em linha com seta.
///
/// Três itens escrevem assim, e cada um com a sua torção — ver
/// [_spanBonusPattern], [_ramoPattern] e [_escadaPattern].
void _lerBonusDeSpan(String tooltip, Map<String, List<int>> attributes) {
  // O site a dizer que não sabe resolver os atributos. Ler o resto daria
  // zero, e zero aqui seria uma afirmação que ninguém verificou.
  if (_naoResolvido.hasMatch(tooltip)) return;

  for (final match in _spanBonusPattern.allMatches(tooltip)) {
    final cor = match.group(1)!.trim().toLowerCase();
    if (cor.contains(_cinzentoDoNaoGanho)) continue;

    var nome = match.group(2)!.trim();
    if (nome.isEmpty) continue;

    // `Destino · Atq Físico` e `Guia · Atq Físico` são o mesmo atributo de
    // dois ramos; `(+3) : Atq Físico` é o mesmo atributo num patamar.
    nome = nome.replaceFirst(_ramoPattern, '').replaceFirst(_escadaPattern, '');
    if (nome.isEmpty) continue;

    // **Decimais arredondados, e o estado guarda a ocorrência.** O conduíte
    // escreve `HP +69.60` e `Atq Físico +2.20`; o índice inteiro é de
    // inteiros, e mudá-lo para decimal tocaria no formato, nos filtros e na
    // tela por causa de três casas. Arredondar perde meio ponto num número
    // que ninguém compara ao decímetro.
    final valor = double.tryParse(match.group(3)!);
    if (valor == null) continue;
    (attributes[nome] ??= <int>[]).add(valor.round());
  }
}

/// O nível do astrolábio ou do conduíte, ou zero quando o item não tem.
///
/// Guardado como contexto e **nunca como medida da força** — ver
/// [_nivelPattern].
int _lerNivel(String tooltip) {
  final match = _nivelPattern.firstMatch(tooltip);
  return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
}

int _firstNumber(RegExp pattern, String? source) {
  if (source == null) return 0;
  final match = pattern.firstMatch(source);
  return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
}

/// The `Títulos` panel, summarised.
///
/// The panel is the richest thing on a character page that nothing used to
/// read: 646 title cards on the fattest one measured, each with an id, a name
/// and its own bonuses, over a summary that says what they add up to. Only
/// the summary and the founder title are kept — the cards themselves are 646
/// strings per character against 1.680 characters, which is a state file an
/// order of magnitude larger to answer a question nobody has asked yet.
///
/// **The summary is kept whole even though no screen reads it**, and that is
/// the rule this collector works by rather than an oversight. It arrives in
/// bytes already being downloaded, it costs nine numbers in the state, and
/// the alternative is paying the eighty-three minutes of a full crawl again
/// the first time somebody asks what titles are worth. One of those numbers
/// is `Nível de ataque`, which ran +2 on one character and +24 on another —
/// a third of the 70-level weapon this whole site exists to compare.
class ParsedTitles {
  const ParsedTitles({
    required this.decoded,
    required this.inOctet,
    required this.equipped,
    required this.attributes,
    required this.founder,
  });

  /// How many titles the page could name.
  final int decoded;

  /// How many the octet claims. It runs higher than [decoded] — 656 against
  /// 646 — so the two are kept apart: flattening them would hide that the
  /// page itself cannot name everything the character holds.
  final int inOctet;

  /// The one title being worn, empty when none is.
  final String equipped;

  /// What every title together grants, as the panel sums it. An attribute the
  /// summary does not list is **absent rather than zero**: zero would assert
  /// the titles grant none of it, which nobody checked.
  final Map<String, int> attributes;

  /// The founder title exactly as the page writes it — `Fundador X` — and
  /// empty when the character has none.
  ///
  /// Raw, not reduced to its rung, for the same reason [parseCelestialRealm]
  /// keeps its row raw: reading the ladder wrong is a mistake to fix with
  /// `--rebuild`, never with another crawl.
  final String founder;
}

/// Everything in `data-pw187-panel="titles"`, or null when the page has no
/// such panel at all.
///
/// Null and not an empty [ParsedTitles]: "this page has no titles panel" and
/// "this character has no titles" are different facts, and only the first may
/// read as unknown.
ParsedTitles? parseTitles(String html) {
  final panel = html_parser
      .parse(html)
      .querySelector('[data-pw187-panel="titles"]');
  if (panel == null) return null;

  final resumo = _labelledNumbers(panel.querySelector('.pw187-title-summary'));

  return ParsedTitles(
    decoded: resumo['Total decodificado'] ?? 0,
    inOctet: resumo['Total no octet'] ?? 0,
    equipped: _labelledText(
      panel.querySelector('.pw187-title-summary'),
      'Equipado',
    ),
    attributes: _labelledNumbers(
      panel.querySelector('.pw187-title-summary-attrs'),
    ),
    founder: _founderIn(panel),
  );
}

/// The title whose name is a founder pack's.
///
/// Matched on the whole name against the ten figures, never on a prefix:
/// `Fundador Ilustre` would otherwise read as `Fundador I`, and a tier
/// invented out of a different title is worse than no tier at all.
String _founderIn(Element panel) {
  for (final card in panel.querySelectorAll('.pw187-title-card')) {
    final nome = card.querySelector('h4')?.text.trim() ?? '';
    for (final romano in romanosAteDez) {
      if (nome == 'Fundador $romano') return nome;
    }
  }
  return '';
}

/// The `<li><span>label</span><strong>value</strong></li>` rows of a block,
/// as numbers. `+24` and `24` are the same number; anything unreadable is
/// left out rather than counted as zero.
Map<String, int> _labelledNumbers(Element? block) {
  final out = <String, int>{};
  for (final row in block?.querySelectorAll('li') ?? const <Element>[]) {
    final label = row.querySelector('span')?.text.trim();
    final raw = row.querySelector('strong')?.text.trim().replaceFirst('+', '');
    final value = int.tryParse(raw ?? '');
    if (label != null && value != null) out[label] = value;
  }
  return out;
}

/// The same rows, read as text — for `Equipado`, whose value is a name.
String _labelledText(Element? block, String label) {
  for (final row in block?.querySelectorAll('li') ?? const <Element>[]) {
    if (row.querySelector('span')?.text.trim() != label) continue;
    return row.querySelector('strong')?.text.trim() ?? '';
  }
  return '';
}
