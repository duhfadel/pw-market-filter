import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/tool.dart';

/// Opens [tool] the way every menu on the site agrees to: [Tool.href] leaves
/// in the same tab, [Tool.route] pushes inside the app. Routing stays with
/// `MaterialApp`, never a nested `Navigator` — a page pushed any other way
/// carries no link of its own, and the browser's back button leaves the site
/// instead of going home.
///
/// One function and not several copies. `Cabecalho`'s grouped menu — the
/// section pills on wide, the overflow menu on narrow — is the only caller
/// left since the front page's own tool cards and guide line were retired on
/// 01/10/2026; a duplicated branch is a duplicated bug the day one copy is
/// fixed and the others are not.
void abrirTool(BuildContext context, Tool tool) {
  final href = tool.href;
  if (href != null) {
    unawaited(launchUrl(Uri.parse(href), webOnlyWindowName: '_self'));
    return;
  }

  // The same hazard **M1** found in the Novidades pill: picking the tool
  // that names the screen already open would push a second, identical copy
  // on top of it, and the back button's first press would appear to do
  // nothing. Compared by path, not by the whole route name — `/filtro` can
  // carry a query string this `route` never will.
  final route = tool.route!;
  final atual = ModalRoute.of(context)?.settings.name;
  if (atual != null && Uri.parse(atual).path == route) return;

  Navigator.of(context).pushNamed(route);
}
