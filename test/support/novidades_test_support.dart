import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';

/// Wraps [child] with a `NovidadesViewModel` — the one `main.dart` provides
/// above every real route, through its `MultiBlocProvider`.
///
/// `Cabecalho`'s own Novidades pill reads this directly with
/// `BlocProvider.of<NovidadesViewModel>(context, listen: true)` and has no
/// fallback for a missing one — deliberately, after `CLAUDE.md`'s own
/// `VisitRepository` incident: a catch written to keep a feature quiet
/// (there, "never let a counter take the page down") swallowed a real bug
/// right along with the thing it was guarding against, and the suite stayed
/// green throughout because its mock never exercised the failure. A silent
/// fallback here would do the same — hide the day a sixth screen genuinely
/// forgets the provider behind an unlit dot that explains nothing. So any
/// test that mounts `Cabecalho`, or a screen that carries it (`NovidadesView`
/// included), needs this wrapper, the same way every real screen needs
/// `main.dart`'s own provider.
///
/// [corpo] is the raw JSON body a fake `NovidadeRepository` answers with — an
/// empty table by default, which is enough for any test that does not care
/// what the pill's dot shows.
Widget comNovidades(Widget child, {Object corpo = const []}) =>
    BlocProvider<NovidadesViewModel>(
      create: (_) => NovidadesViewModel(
        NovidadeRepository(
          MockClient((_) async => http.Response(jsonEncode(corpo), 200)),
        ),
      )..load(),
      child: child,
    );
