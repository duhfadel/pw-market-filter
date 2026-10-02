/// The site's URL space, with two marketplaces living under it.
///
/// `main.dart`'s `onGenerateRoute` used to compare a route's path to five
/// literal strings. That stopped being enough the moment a second
/// marketplace needed its own home and its own filter: `/filtro` cannot mean
/// both "the 1.8.7 filter" and "the 1.2.6 filter" at once, so every screen
/// that is specific to a version now lives under that version's prefix —
/// `/1.8.7/filtro`, `/1.2.6/filtro` — while `/novidades` stays bare, because
/// it speaks about the site and not about either game.
///
/// [resolverRota] is a pure function on purpose: every row of the table below
/// can be asserted without building a `MaterialApp`, a `Navigator`, or a
/// widget tree.
///
/// ```
/// /                    a escolha
/// /1.8.7               a home do 1.8.7
/// /1.8.7/filtro        o filtro         (canónica daqui para a frente)
/// /filtro?...          redireciona      (links já partilhados, para sempre)
/// /1.8.7/registros     Títulos
/// /1.8.7/runas         Runas
/// /1.2.6               a home do 1.2.6
/// /1.2.6/filtro        o filtro do 1.2.6
/// /novidades           uma só, serve as duas
/// ```
library;

import 'package:flutter/material.dart';

/// The 1.8.7 marketplace's prefix — the version that was already live before
/// this file existed, which is the whole reason `/filtro` has to keep working
/// forever: see [RotaRedirecionada].
const pw187 = '1.8.7';

/// The 1.2.6 marketplace's prefix.
const pw126 = '1.2.6';

/// [pw187] or [pw126] — the readable label `Cabecalho.versao` draws — from
/// `MarketIndex.server`/`IndexRepository.server` (`'pw187'`, `'pw126'`), the
/// file key rather than the number a visitor reads.
///
/// An index cannot carry anything else: `IndexRepository.fileName` already
/// refuses an unknown `server` before any screen gets this far, so this is
/// a lookup and never a guess.
String versaoDoServidor(String server) => switch (server) {
  'pw187' => pw187,
  'pw126' => pw126,
  _ => throw ArgumentError.value(server, 'server', 'unknown marketplace'),
};

/// Every screen a URL can resolve to. Named rather than built here —
/// `main.dart` owns the widgets, this file only owns which URL means which
/// name, so a test can assert the mapping without importing a single view.
enum Tela {
  /// The landing choice between the two marketplaces — `PortasView`,
  /// `features/portas/ui/portas_view.dart`. `/` no longer opens the 1.8.7
  /// home directly; every link shared in the community already names a
  /// version and never passes through here.
  escolha,
  home187,
  home126,
  filtro187,
  filtro126,
  registros,
  runas,
  novidades,
}

/// What a URL means: either a screen to render now, or a legacy path that
/// must become somewhere else — see [RotaTela] and [RotaRedirecionada].
sealed class RotaResolvida {
  const RotaResolvida();
}

/// Render [tela] for a URL that is already canonical.
class RotaTela extends RotaResolvida {
  const RotaTela(this.tela, {this.query = const {}});

  final Tela tela;

  /// The address bar's query parameters, forwarded to whichever screen reads
  /// them — today only the two filter screens do, and only to rebuild a
  /// shared search (`search_query_url.dart`).
  final Map<String, List<String>> query;
}

/// A link that predates the version prefixes, now permanently kept alive by
/// pointing it at [destino] instead.
///
/// **This is not a migration step.** `/filtro` is pasted across the
/// community already, and it has to keep opening the right search for as
/// long as this site exists — nothing here may ever be deleted on the theory
/// that "everyone has switched to the new link by now". See [resolverRota]'s
/// handling of `/filtro` and [LegacyRedirect], which is what actually sends
/// the browser there.
class RotaRedirecionada extends RotaResolvida {
  const RotaRedirecionada(this.destino);

  /// Where to send the visitor — path and query together, exactly as
  /// [resolverRota] read them off the old link.
  final String destino;
}

/// Reads one URL — `settings.name`, typically — and says what it means.
RotaResolvida resolverRota(String? name) {
  final uri = Uri.parse(name ?? '/');
  final segments = uri.pathSegments;

  // The one path that predates the two marketplaces, and the whole reason
  // the redirect exists: a link shared before today carries the entire
  // search encoded in its query string (`search_query_url.dart`), and that
  // string has to travel untouched — an empty filter at the far end would
  // read as the search having broken rather than moved.
  //
  // **This is a reader only, forever, and never a writer again.** Nothing in
  // this app may produce a bare `/filtro` link from here on —
  // `AddressBar.canonicalFiltro` and `tool.dart`'s own route both point at
  // `/1.8.7/filtro` already. If this match is ever removed on the theory that
  // "nothing writes it any more", every link already pasted in the community
  // 404s on the spot.
  if (uri.path == '/filtro') {
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return RotaRedirecionada('/$pw187/filtro$query');
  }

  if (segments.isEmpty) return const RotaTela(Tela.escolha);

  if (segments.first == 'novidades' && segments.length == 1) {
    return const RotaTela(Tela.novidades);
  }

  // `/registros` and `/runas`, bare, kept alongside their new prefixed
  // spellings below. Both were already linked from the front page before
  // this file existed (`CLAUDE.md`: "`/registros` tem um card na página
  // inicial"), and a link that already works may not start 404ing because
  // the site grew a second marketplace.
  if (segments.first == 'registros' && segments.length == 1) {
    return const RotaTela(Tela.registros);
  }
  if (segments.first == 'runas' && segments.length == 1) {
    return const RotaTela(Tela.runas);
  }

  if (segments.first == pw187) {
    if (segments.length == 1) return const RotaTela(Tela.home187);
    if (segments[1] == 'filtro') {
      return RotaTela(Tela.filtro187, query: uri.queryParametersAll);
    }
    if (segments[1] == 'registros') return const RotaTela(Tela.registros);
    if (segments[1] == 'runas') return const RotaTela(Tela.runas);
    return const RotaTela(Tela.home187);
  }

  if (segments.first == pw126) {
    if (segments.length == 1) return const RotaTela(Tela.home126);
    if (segments[1] == 'filtro') {
      return RotaTela(Tela.filtro126, query: uri.queryParametersAll);
    }
    return const RotaTela(Tela.home126);
  }

  return const RotaTela(Tela.escolha);
}

/// Sends a legacy, unprefixed link to its canonical new home — permanently,
/// see [RotaRedirecionada].
///
/// `pushReplacementNamed`, never `pushNamed`: replacing the current history
/// entry is what keeps the back button from landing on the old link and
/// redirecting again, trapping whoever clicked it in a loop. The call waits
/// for the first frame because the route that builds this widget is itself
/// mid-build while `initState` runs — the `Navigator` that owns it has not
/// finished settling the push that put this very screen on screen, and a
/// second navigation from inside that is the wrong moment to start one.
class LegacyRedirect extends StatefulWidget {
  const LegacyRedirect({super.key, required this.destino});

  /// Where this screen sends the visitor, as soon as it is mounted.
  final String destino;

  @override
  State<LegacyRedirect> createState() => _LegacyRedirectState();
}

class _LegacyRedirectState extends State<LegacyRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.destino);
    });
  }

  // Nothing to show: a redirect is instantaneous on the frame after this one,
  // and this widget is never the thing a visitor looks at.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
