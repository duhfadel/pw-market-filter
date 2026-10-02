import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The browser's address bar, as far as the filter is concerned.
///
/// Only the filter writes here, because the filter is the only screen whose
/// state is worth a link. That is why the method names the route instead of
/// taking one: a second caller writing a different path would need a reason,
/// and would have to say so here.
///
/// **This is the one canonical writer, and `/filtro` is only ever a reader.**
/// `core/rotas.dart` keeps `/filtro` alive forever for links already pasted
/// in the community, but nothing in this app may ever *produce* that bare
/// path again — every new link has to carry the version from the moment it
/// is written, or the redirect's job never shrinks. If something here is ever
/// "simplified" back to writing `/filtro`, every link shared from that day on
/// becomes a legacy link on arrival.
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
  const AddressBar();

  /// The canonical path for the 1.8.7 filter — the one this app ever writes.
  /// `core/rotas.dart`'s `pw187` constant names the same version; this one is
  /// not built from it only because that file deliberately imports nothing
  /// from `features/`, and a single string is cheaper to keep in sync by hand
  /// than a dependency the other way would be.
  static const canonicalFiltro = '/1.8.7/filtro';

  /// The address [query] belongs at, as a [Uri] rather than a built string so
  /// both callers below — and a test — share the one place that knows the
  /// path.
  static Uri uriFor(String query) =>
      Uri(path: canonicalFiltro, query: query.isEmpty ? null : query);

  /// The absolute address of [query], for handing to somebody else.
  ///
  /// Built from [base] rather than read off the address bar so it survives the
  /// page having been opened with something else in its own query string — the
  /// link shared should be the search, not whatever else came along.
  static String linkTo(Uri base, String query) {
    final root = '${base.scheme}://${base.authority}${base.path}';
    final uri = uriFor(query);
    return '$root#${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
  }

  /// [query] is a query string without its leading `?`; empty clears it.
  void writeFilter(String query) {
    // Outside a browser there is no address bar to write to, and reaching for
    // the platform channel there would only be the test suite talking to
    // nothing. `BrowserMemory` splits the same way, for the same reason.
    if (!kIsWeb) return;

    SystemNavigator.routeInformationUpdated(uri: uriFor(query), replace: true);
  }
}
