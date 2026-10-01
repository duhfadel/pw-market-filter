/// The per-version profile of a Classic PW marketplace.
///
/// Pure Dart, no `dart:io` — it lives in `lib/collector/` so the tests can
/// call it and so `tool/collect.dart` has a single place to read what varies
/// between versions instead of scattering `pw187`/`pw126` literals.
class Servidor {
  const Servidor._({
    required this.chave,
    required this.origem,
    required this.arquivoDoIndice,
    required this.prefixoCss,
    required this._detalhe,
  });

  /// The version's short name, as it appears in the site's own paths:
  /// `pw187`, `pw126`.
  final String chave;

  /// The marketplace's origin. Shared by both versions today, but kept per
  /// profile rather than hard-coded at every call site.
  final String origem;

  /// Where this version's collection is written. Kept separate per version so
  /// a 1.2.6 run can never overwrite the 1.8.7 index, or the other way round.
  final String arquivoDoIndice;

  /// The CSS class prefix this version's pages use — `pw187-`, `pw126-`.
  final String prefixoCss;

  final String Function(int roleId) _detalhe;

  /// The canonical detail URL for a character — the form that answers 200
  /// without a redirect. **Inverted between the two versions**, measured
  /// 01/10/2026: `pw187/details/<id>` is canonical and `details/pw187/<id>`
  /// redirects into it; `details/pw126/<id>` is canonical and
  /// `pw126/details/<id>` answers 404. Copying one version's shape onto the
  /// other is the natural mistake.
  String detalhe(int roleId) => _detalhe(roleId);

  static const _origem = 'https://marketplace.theclassic.games';

  /// Known versions. An unknown key is refused rather than guessed — a typo
  /// silently collecting against a 404 for forty minutes would write an
  /// empty index that overwrites a good one.
  static final _conhecidos = <String, Servidor>{
    'pw187': Servidor._(
      chave: 'pw187',
      origem: _origem,
      arquivoDoIndice: 'web/market_index.json',
      prefixoCss: 'pw187-',
      detalhe: (roleId) => '$_origem/pw187/details/$roleId',
    ),
    'pw126': Servidor._(
      chave: 'pw126',
      origem: _origem,
      arquivoDoIndice: 'web/market_index_126.json',
      prefixoCss: 'pw126-',
      detalhe: (roleId) => '$_origem/details/pw126/$roleId',
    ),
  };

  /// Looks up a version by its key. Throws [ArgumentError] for anything not
  /// in [_conhecidos] — refusing loudly beats guessing a shape that would
  /// quietly collect nothing.
  factory Servidor.de(String chave) {
    final servidor = _conhecidos[chave];
    if (servidor == null) {
      throw ArgumentError.value(
        chave,
        'chave',
        'servidor desconhecido — versões conhecidas: '
            '${_conhecidos.keys.join(', ')}',
      );
    }
    return servidor;
  }
}
