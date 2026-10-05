import '../market/endereco_do_mercado.dart';
import 'detail_parser.dart' show ParsedItem, parseEquippedItems, parseSex;
import 'detail_parser_126.dart'
    show
        EspacoDeItens,
        MascoteDoPersonagem,
        parseEquippedItems126,
        parseEspacos126,
        parseMascotes126,
        parsePericias126,
        parseSex126;

Map<String, EspacoDeItens> _nenhumEspaco(String _) => const {};
List<MascoteDoPersonagem> _nenhumMascote(String _) => const [];
Map<int, int> _nenhumaPericia(String _) => const {};

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
    required this.arquivoDoEstado,
    required this.indicePublicado,
    required this.itensEquipados,
    required this.sexo,
    required this.espacos,
    required this.mascotes,
    required this.pericias,
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

  /// Where this version's collector state — what has already been read,
  /// resumable — is kept. **Must stay separate per version**: a shared file
  /// means a `pw126` run loads the `pw187` state, sees 1.308 role ids it does
  /// not recognise, and `pruneTo` deletes every `pw187` entry for not being
  /// on the 126 listing — forty minutes of collected state gone with nothing
  /// on screen saying so, and the next `pw187` run re-crawling the whole
  /// market. `pw187` keeps the path that already exists on disk today, so
  /// this change orphans no state already sitting on the collector's machine.
  final String arquivoDoEstado;

  /// The URL this version's own published index is read from, to carry price
  /// history and `firstSeen` forward. Kept per version so a `pw126` run never
  /// compares the 126 market against the 187 index — that would produce
  /// first-seen and price-drop records that are pure nonsense, and nothing
  /// would error to say so.
  final String indicePublicado;

  /// This version's own parser for the worn items — the whole reason the two
  /// versions are kept apart at all. Wiring this per version, rather than
  /// hard-coding the 1.8.7 parser at the one call site in `tool/collect.dart`,
  /// is what makes `--server pw126` collect attributes instead of eleven bare
  /// items: see `detail_parser_126.dart`'s `parseEquippedItems126` for what a
  /// 1.2.6 page requires that a 1.8.7 one does not.
  final List<ParsedItem> Function(String html) itensEquipados;

  /// This version's own reader for the `Sexo` row. Both read the same
  /// `.character-info--list` shape today — `parseSex126` says so in its own
  /// docstring — but it is still per-version so a future divergence costs a
  /// change here, not a hunt through `tool/collect.dart`.
  final String Function(String html) sexo;

  /// The three readers that only one marketplace has anything for. A version
  /// without them answers empty, which is the right answer rather than a gap:
  /// `Itens do Personagem`, the pet cage and the per-skill badges do not
  /// exist on a 1.8.7 page at all.
  final Map<String, EspacoDeItens> Function(String html) espacos;
  final List<MascoteDoPersonagem> Function(String html) mascotes;
  final Map<int, int> Function(String html) pericias;

  final String Function(int roleId) _detalhe;

  /// The canonical detail URL for a character, from the one table that holds
  /// the shape — see [enderecoDoPersonagem], which also records why it is
  /// inverted between the two versions. It lives in `market/` rather than
  /// here because the results card needs the same answer, and `features/`
  /// may never reach into `collector/`.
  ///
  /// Still a field per profile rather than a direct call, so a version that
  /// one day needs a query string or a different host has somewhere to say
  /// so without the screen inheriting it.
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
      arquivoDoEstado: 'tool/.collect_state.json',
      indicePublicado: 'https://portalpw.net/market_index.json',
      itensEquipados: parseEquippedItems,
      sexo: parseSex,
      espacos: _nenhumEspaco,
      mascotes: _nenhumMascote,
      pericias: _nenhumaPericia,
      detalhe: (roleId) => enderecoDoPersonagem('pw187', roleId),
    ),
    'pw126': Servidor._(
      chave: 'pw126',
      origem: _origem,
      arquivoDoIndice: 'web/market_index_126.json',
      arquivoDoEstado: 'tool/.collect_state_126.json',
      indicePublicado: 'https://portalpw.net/market_index_126.json',
      itensEquipados: parseEquippedItems126,
      sexo: parseSex126,
      espacos: parseEspacos126,
      mascotes: parseMascotes126,
      pericias: parsePericias126,
      detalhe: (roleId) => enderecoDoPersonagem('pw126', roleId),
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
