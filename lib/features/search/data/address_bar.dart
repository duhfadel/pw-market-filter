import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/rotas.dart' show versaoDoServidor;
import '../../../market/index_repository.dart' show IndexRepository;

/// The browser's address bar, as far as the filter is concerned.
///
/// Only the filter writes here, because the filter is the only screen whose
/// state is worth a link. That is why the method names the route instead of
/// taking one: a second caller writing a different path would need a reason,
/// and would have to say so here.
///
/// **This is the one canonical writer per marketplace, and `/filtro` is only
/// ever a reader.** `core/rotas.dart` keeps `/filtro` alive forever for links
/// already pasted in the community, but nothing in this app may ever
/// *produce* that bare path again — every new link has to carry the version
/// from the moment it is written, or the redirect's job never shrinks. If
/// something here is ever "simplified" back to writing `/filtro`, every link
/// shared from that day on becomes a legacy link on arrival.
///
/// **One writer, two versions — not two writers.** An instance is built for
/// the marketplace it speaks for ([server]), and every path it produces is
/// derived from that, through [versaoDoServidor] — the same lookup
/// `core/rotas.dart` already uses to turn `MarketIndex.server` into the
/// version a visitor reads. Hardcoding `/1.8.7/filtro` here, the way this
/// class once did, is exactly how a 1.2.6 search ended up rewriting its own
/// address into the 1.8.7 market: nothing in the write path ever asked which
/// version it was writing for.
///
/// The write **replaces** the current history entry rather than pushing one.
/// Pushing would fill the back button with a state per keystroke, and the back
/// button on this site has one job — going home.
///
/// [SystemNavigator.routeInformationUpdated] is used instead of touching
/// `history` through `package:web` so the app's own history stays in agreement
/// with the address bar; two writers on one history is how a back button starts
/// skipping pages.
class AddressBar {
  /// [server] is `IndexRepository.pw187` or `.pw126` — defaults to pw187 so
  /// every call site written before the second marketplace existed keeps
  /// writing the path it always has.
  const AddressBar([this.server = IndexRepository.pw187]);

  /// The marketplace this instance writes for.
  final String server;

  /// The canonical path for the 1.8.7 filter, kept as a literal constant for
  /// the call sites that only ever mean 1.8.7 — the legacy `/filtro` redirect
  /// target and the menu's own tool entry, both pinned by `rotas_test.dart`.
  /// [pathFor] is the version-aware form everything that can be asked about
  /// either marketplace goes through instead.
  static const canonicalFiltro = '/1.8.7/filtro';

  /// The canonical filter path for [server].
  static String pathFor(String server) => '/${versaoDoServidor(server)}/filtro';

  /// The address [query] belongs at for [server], as a [Uri] rather than a
  /// built string so every caller — and a test — share the one place that
  /// knows the path.
  static Uri uriFor(String query, {String server = IndexRepository.pw187}) =>
      Uri(path: pathFor(server), query: query.isEmpty ? null : query);

  /// The absolute address of [query] at [server], for handing to somebody
  /// else.
  ///
  /// Built from [base] rather than read off the address bar so it survives the
  /// page having been opened with something else in its own query string — the
  /// link shared should be the search, not whatever else came along.
  static String linkTo(
    Uri base,
    String query, {
    String server = IndexRepository.pw187,
  }) {
    final root = '${base.scheme}://${base.authority}${base.path}';
    final uri = uriFor(query, server: server);
    return '$root#${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  }

  /// [query] is a query string without its leading `?`; empty clears it.
  void writeFilter(String query) {
    // Outside a browser there is no address bar to write to, and reaching for
    // the platform channel there would only be the test suite talking to
    // nothing. `BrowserMemory` splits the same way, for the same reason.
    if (!kIsWeb) return;

    SystemNavigator.routeInformationUpdated(
      uri: uriFor(query, server: server),
      replace: true,
    );
  }
}
