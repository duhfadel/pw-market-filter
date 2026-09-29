/// Lowercases and strips the accents a Brazilian nickname carries, so that a
/// name typed one way finds a name spelled the other.
///
/// **Both directions matter, and that is the whole point.** The market is
/// Brazilian and half the nicknames carry an accent, so somebody typing
/// `joao` on a phone keyboard has to find `João`; and somebody pasting `João`
/// straight out of the game has to find him too, whichever way the index
/// spells it. Folding both the haystack and the needle is what makes the
/// comparison symmetric — folding only one side quietly works in one
/// direction and fails in the other, which is the shape of bug nobody
/// reports because they assume they typed it wrong.
///
/// **Written by hand rather than reached for in a package.** Dart's core
/// library does no Unicode normalisation, and `CLAUDE.md` forbids a new
/// dependency without asking. The table below is the Portuguese the market
/// actually uses, plus the Spanish `ñ` and the `ü` that survive in borrowed
/// nicknames. A letter not in the table travels through untouched, which is
/// the right failure: an unfolded character still matches itself, so an
/// unforeseen accent narrows the search rather than breaking it.
///
/// Nothing else is stripped. `??SK??` is a real nickname in this market, and
/// removing punctuation from the haystack would make it unfindable by the
/// only thing that distinguishes it.
String foldForSearch(String text) {
  final folded = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    folded.write(
      _accents[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
    );
  }
  return folded.toString();
}

/// Lowercase only — [foldForSearch] lowercases before it looks anything up,
/// so the capitals would be dead entries.
const _accents = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
};
