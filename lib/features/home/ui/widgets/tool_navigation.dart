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
/// One function and not three copies. `Cabecalho`'s grouped menu, `ToolCard`
/// and the front page's guide line each open a `Tool`, and until this file
/// existed the first two carried byte-identical private functions doing it —
/// a duplicated branch is a duplicated bug the day one copy is fixed and the
/// others are not.
void abrirTool(BuildContext context, Tool tool) {
  final href = tool.href;
  if (href != null) {
    unawaited(launchUrl(Uri.parse(href), webOnlyWindowName: '_self'));
    return;
  }
  Navigator.of(context).pushNamed(tool.route!);
}
