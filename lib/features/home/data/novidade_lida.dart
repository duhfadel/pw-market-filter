import '../domain/novidade.dart';
import 'browser_memory.dart';

/// Whether this browser has opened `/novidades` since the newest entry was
/// posted — one fact, read by the header's pill (`cabecalho.dart`) and
/// written by the screen itself (`novidades_view.dart`). Centralising both
/// halves behind one key and one comparison is what keeps them from drifting
/// the way two hand-copied `localStorage` keys would — the exact hazard
/// `BrowserMemory`'s own docstring already names for the visit counter.
///
/// `BrowserMemory` stores the ISO-8601 timestamp of the newest entry this
/// browser is known to have seen. `null` — nothing stored — means never, and
/// that is the useful direction to be wrong in: a first-time visitor has
/// read none of it, so defaulting to "something new" is right far more often
/// than defaulting to "all caught up".
class NovidadeLida {
  NovidadeLida([BrowserMemory? memoria])
    : _memoria = memoria ?? BrowserMemory.platform(_chave);

  static const _chave = 'portal_pw_ultima_novidade';

  final BrowserMemory _memoria;

  /// Something posted after whatever this browser last marked as read. An
  /// empty list never counts as new — there is nothing yet to announce.
  bool existeNaoLida(List<Novidade> entradas) {
    if (entradas.isEmpty) return false;
    return _memoria.read() != _marca(entradas);
  }

  /// Marks the newest of [entradas] as seen. A no-op on an empty list: there
  /// is nothing to remember having read.
  void marcarComoLida(List<Novidade> entradas) {
    if (entradas.isEmpty) return;
    _memoria.write(_marca(entradas));
  }

  /// The newest entry's own timestamp, found by comparison rather than
  /// assumed from list order — the repository's query happens to sort
  /// descending, but a fact this small is cheap to make true by
  /// construction instead of by trusting a caller's order.
  static String _marca(List<Novidade> entradas) => entradas
      .map((e) => e.publicadaEm)
      .reduce((a, b) => a.isAfter(b) ? a : b)
      .toIso8601String();
}
