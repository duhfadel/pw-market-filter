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
    this.escada = const [],
    this.bonusNaoResolvidos = false,
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
        escada: escada,
        bonusNaoResolvidos: bonusNaoResolvidos,
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

  /// A escada de refino do livro divino, com os degraus por alcançar.
  /// Vazia em tudo o resto. Ver [PatamarDoLivro].
  final List<PatamarDoLivro> escada;

  /// O site a dizer que não sabe: *"Atributos do Conduíte não resolvidos."*
  ///
  /// **Terceiro estado, e é por isso que existe um campo em vez de uma lista
  /// vazia.** Um conduíte sem bónus e um conduíte cujos bónus a página não
  /// resolve dão os dois `attributes` vazio, e são factos diferentes: o
  /// primeiro é sobre o personagem, o segundo é sobre o site deles. Sem esta
  /// marca o índice afirmaria um zero que ninguém verificou, e a tela não
  /// teria como dizer *"não sabemos"* em vez de *"não tem"*.
  ///
  /// Quantos são, não se sabe ainda: visto num conduíte de nível 2, e três
  /// páginas não dizem se é raro — foi esse o erro que custou o piso do
  /// `Cupom Perfeito`. A recolha conta-os.
  final bool bonusNaoResolvidos;

  final Map<String, List<double>> attributes;

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
/// Sai do nome: os dois ramos são fontes do mesmo atributo, não atributos
/// diferentes — quem tem `Destino · Espírito +155` e `Guia · Espírito +83`
/// tem 238 de espírito, e dois nomes dividiriam em duas colunas uma coisa
/// que o jogador soma. Ver a nota em `_lerBonusDeSpan` para a volta que esta
/// decisão deu.
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
    escada: _lerEscada(tooltip),
    bonusNaoResolvidos: _naoResolvido.hasMatch(tooltip),
  );
}

/// Um degrau da escada de refino do livro divino.
///
/// **Guardada inteira, com os que faltam, por decisão do dono em
/// 20/10/2026.** Eu tinha deitado fora os patamares por alcançar; ele quer o
/// que o jogo mostra — a escada toda, com o que falta a cinzento. É a
/// diferença entre dizer *"este livro dá isto"* e dizer *"este livro dá isto
/// e ainda pode dar aquilo"*, e a segunda é a que ajuda quem está a comprar.
///
/// Os ganhos continuam a entrar em [ParsedItem.attributes], e os por ganhar
/// **não**: um filtro que pergunte por `Nv. de Ataque +15` não pode devolver
/// quem ainda não lá chegou. A escada é para mostrar; os atributos são para
/// filtrar.
class PatamarDoLivro {
  const PatamarDoLivro({
    required this.refino,
    required this.atributo,
    required this.valor,
    required this.ganho,
  });

  /// O refino que este degrau exige: 3, 6, 9, 12, 15.
  final int refino;

  final String atributo;
  final int valor;

  /// Se o personagem já lá chegou. Verde na página, cinzento quando não.
  final bool ganho;
}

/// A single item can carry the same bonus more than once — the weapon in the
/// fixture lists `HP +500`, `HP +150`, `HP +150`. Every occurrence is kept, in
/// order; overwriting on collision would report 150 where the item gives 800,
/// and summing here would report 71 for a weapon whose principal is 70.
///
/// **Decimal, e não inteiro, desde 20/10/2026.** O conduíte escreve `HP
/// +69.60` e o livro divino `Intervalo de Ataque -0.05s`. Arredondar custava
/// meio ponto no primeiro e **o facto inteiro** no segundo: `-0.05` vira `0`,
/// que lido na tela diz *não muda* quando muda. Tentei contornar guardando
/// centésimos com a unidade no nome — `Intervalo de Ataque (0,01 s)` — e o
/// dono recusou, com razão: um número que precisa de um nome a explicar a
/// escala já não é o número que a página mostra.
Map<String, List<double>> _readAttributes(String tooltip) {
  final attributes = <String, List<double>>{};

  for (final match in _attributePattern.allMatches(tooltip)) {
    final name = match.group(1)!.trim();
    if (name.isEmpty) continue;
    final value = double.tryParse(match.group(2)!);
    if (value == null) continue;
    (attributes[name] ??= <double>[]).add(value);
  }

  _lerBonusDeSpan(tooltip, attributes);
  _lerBlocos(tooltip, attributes);
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
void _lerBonusDeSpan(String tooltip, Map<String, List<double>> attributes) {
  // O site a dizer que não sabe resolver os atributos. Ler o resto daria
  // zero, e zero aqui seria uma afirmação que ninguém verificou.
  if (_naoResolvido.hasMatch(tooltip)) return;

  for (final match in _spanBonusPattern.allMatches(tooltip)) {
    final cor = match.group(1)!.trim().toLowerCase();
    if (cor.contains(_cinzentoDoNaoGanho)) continue;

    var nome = match.group(2)!.trim();
    if (nome.isEmpty) continue;

    // **Uma linha de seta já tem o seu leitor.** A arma do Leandrim escreve
    // cada bónus dentro do seu `<span>` *com* o `➜` lá dentro, portanto este
    // padrão apanha-os todos outra vez — e com a seta colada ao nome, o que
    // duplicava cada atributo da arma em duas entradas. Apanhado por uma
    // sonda sobre a fixture, nunca por um teste: os testes olhavam para os
    // três itens novos e a arma era o controlo que ninguém reimprimia.
    if (nome.startsWith('➜')) continue;

    // Duas coisas saem do nome, e por motivos diferentes.
    //
    // O patamar — `(+3) : Atq Físico` é Atq Físico num degrau da escada, e o
    // degrau inteiro vai para [ParsedItem.escada].
    //
    // E o ramo do astrolábio: `Destino · Atq Físico` e `Guia · Atq Físico`
    // são o mesmo atributo de duas fontes. **Decidido duas vezes**: tirei-o,
    // o dono mandou mantê-lo, viu os nove nomes compridos que isso dava num
    // astrolábio de nível 57 e mandou tirá-lo outra vez. A segunda decisão é
    // a que vale, e a primeira ficou registada porque explica porque é que a
    // forma `Destino ·` aparece no padrão em vez de o nome vir limpo.
    //
    // É recuperável nos dois sentidos: mudar de ideias custa `--rebuild` e
    // nunca outra recolha, porque o estado guarda a ocorrência e não a soma.
    nome = nome.replaceFirst(_escadaPattern, '').replaceFirst(_ramoPattern, '');
    if (nome.isEmpty) continue;

    final valor = double.tryParse(match.group(3)!);
    if (valor == null) continue;
    (attributes[nome] ??= <double>[]).add(valor);
  }
}

/// A escada de refino do livro divino, inteira — os degraus ganhos e os que
/// faltam, cada um com a marca.
///
/// Um livro `Cosmos +12` imprime `(+3)`, `(+6)`, `(+9)` e `(+12)` a verde e
/// `(+15)` a cinzento. Em tudo o que não é livro a lista sai vazia, porque
/// nenhum outro item escreve degraus.
List<PatamarDoLivro> _lerEscada(String tooltip) {
  if (_naoResolvido.hasMatch(tooltip)) return const [];

  final degraus = <PatamarDoLivro>[];
  for (final match in _spanBonusPattern.allMatches(tooltip)) {
    final texto = match.group(2)!.trim();
    final degrau = _escadaPattern.firstMatch(texto);
    if (degrau == null) continue;

    final valor = double.tryParse(match.group(3)!);
    if (valor == null) continue;

    degraus.add(
      PatamarDoLivro(
        refino: int.parse(degrau.group(1)!),
        atributo: texto.replaceFirst(_escadaPattern, '').trim(),
        valor: valor.round(),
        ganho: !match.group(1)!.toLowerCase().contains(_cinzentoDoNaoGanho),
      ),
    );
  }
  return degraus;
}

/// Um bloco de vários bónus dentro de **um** `<span>`, separados por `<br>`.
///
/// É assim que o livro divino escreve os bónus que tem por ser o que é —
/// `Força +50`, `Canalização -5%`, `Intervalo de Ataque -0.05s` — ao
/// contrário da escada de refino, que varia com o personagem. Um `<span>` por
/// bónus nunca apanharia estes, porque o padrão pára no primeiro `<`.
/// **Exige pelo menos um `<br>` lá dentro, e isso não é detalhe.** Sem essa
/// exigência o padrão casa também com os `<span>` de uma linha que
/// [_lerBonusDeSpan] já leu, e tudo sai a dobrar — medido na arma do
/// Leandrim, que veio com `HP [500, 150, 150, 500, 150, 150]` e com o `➜`
/// colado ao nome. Um bloco é, por definição, mais do que uma linha.
final _blocoPattern = RegExp(
  r'<span[^>]*?color:\s*([^;"]+)[^>]*>((?:[^<]*<br\s*/?>)+[^<]*)</span>',
);

/// Uma linha dentro de um bloco: `Canalização -5%`, `Maior Nível +5`.
final _linhaDoBloco = RegExp(r'^\s*(.+?)\s*([+-][\d.]+)\s*(%|s)?\s*$');

/// Lê os bónus que vêm agrupados num `<span>` só.
///
/// **A unidade entra no nome, porque o valor não a sabe carregar.** O índice
/// guarda inteiros; `Canalização -5%` como `-5` diria pontos onde há
/// percentagem, que é o mesmo erro do `Movimento m/seg. +1036831949` já
/// registado neste repositório. `Canalização %` resolve-o sem inventar nada.
///
/// **E um valor que arredondasse para zero é escalado em vez de perdido.**
/// `Intervalo de Ataque -0.05s` arredondado dá `0`, que lido na tela diz *não
/// muda* — e muda. Nesses casos o número vai em centésimos e o nome di-lo:
/// `Intervalo de Ataque (0,01 s)` com valor `-5`. A regra dispara só onde é
/// precisa; `HP +69.60` continua a ser `70`, porque arredondar ali custa meio
/// ponto e não a informação toda.
void _lerBlocos(String tooltip, Map<String, List<double>> attributes) {
  for (final bloco in _blocoPattern.allMatches(tooltip)) {
    if (bloco.group(1)!.toLowerCase().contains(_cinzentoDoNaoGanho)) continue;

    for (final linha in bloco.group(2)!.split(RegExp(r'<br\s*/?>'))) {
      final match = _linhaDoBloco.firstMatch(linha.replaceAll('\n', ' '));
      if (match == null) continue;

      var nome = match.group(1)!.trim();
      final bruto = double.tryParse(match.group(2)!);
      if (nome.isEmpty || bruto == null) continue;

      // **Uma linha de seta já tem leitor, e relê-la conta a dobrar.** A arma
      // do Leandrim escreve os nove bónus dela dentro de um `<span>` só, com
      // `<br>` entre eles e um `➜` à frente de cada um — exactamente a forma
      // que este bloco apanha. Sem esta linha ela saía com
      // `HP [500, 150, 150, 500, 150, 150]` e com o `➜` colado ao nome.
      if (nome.startsWith('➜')) continue;

      // Uma linha com degrau já foi lida como degrau; lê-la aqui outra vez
      // contá-la-ia duas vezes.
      if (_escadaPattern.hasMatch(nome)) continue;

      // A unidade entra no nome: o valor não a sabe carregar, e `-5` sem o
      // `%` diria pontos onde há percentagem — o mesmo erro do
      // `Movimento m/seg. +1036831949` já registado aqui.
      final unidade = match.group(3);
      if (unidade != null) nome = '$nome $unidade';

      (attributes[nome] ??= <double>[]).add(bruto);
    }
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
