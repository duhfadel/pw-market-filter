import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The browser's address bar, as far as the filter is concerned.
///
/// Only the filter writes here, because the filter is the only screen whose
/// state is worth a link. That is why the method names the route instead of
/// taking one: a second caller writing a different path would need a reason,
/// and would have to say so here.
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

  /// The absolute address of [query], for handing to somebody else.
  ///
  /// Built from [base] rather than read off the address bar so it survives the
  /// page having been opened with something else in its own query string — the
  /// link shared should be the search, not whatever else came along.
  static String linkTo(Uri base, String query) {
    final root = '${base.scheme}://${base.authority}${base.path}';
    return query.isEmpty ? '$root#/filtro' : '$root#/filtro?$query';
  }

  /// [query] is a query string without its leading `?`; empty clears it.
  void writeFilter(String query) {
    // Outside a browser there is no address bar to write to, and reaching for
    // the platform channel there would only be the test suite talking to
    // nothing. `VisitMemory` splits the same way, for the same reason.
    if (!kIsWeb) return;

    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: '/filtro', query: query.isEmpty ? null : query),
      replace: true,
    );
  }
}
