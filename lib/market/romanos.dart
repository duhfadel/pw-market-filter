/// Roman figures one to ten, both ways.
///
/// Two ladders on this site are written in Roman: the celestial realm's ten
/// steps and the founder packs. The realm's section already carried a private
/// table of the ten, and the founder parser needs the same ten read backwards
/// — so the table lives here once, where `market/` can be reached by the
/// collector and by the screen alike, rather than in a third hand-typed copy.
///
/// Ten and no further on purpose: both ladders stop at X, and a general Roman
/// numeral converter would be code answering a question nobody asked.
const romanosAteDez = [
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
];

/// `3` becomes `III`. Outside one to ten, the number itself — a ladder that
/// grew an eleventh rung should print something wrong-looking rather than
/// throw a page away.
String romanoDe(int grau) => grau >= 1 && grau <= romanosAteDez.length
    ? romanosAteDez[grau - 1]
    : '$grau';

/// `III` becomes `3`, and anything else becomes null.
///
/// Case-sensitive and whole-string: the page writes them in capitals, and
/// being lenient here would let `Fundador Ilustre` read as `Fundador I`.
int? grauDoRomano(String romano) {
  final i = romanosAteDez.indexOf(romano);
  return i < 0 ? null : i + 1;
}
