import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/core/memoria/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/visit_repository.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/visit_counter_view_model.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';

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

/// Wraps [child] with a `VisitCounterViewModel` — the other one `main.dart`
/// provides above every real route.
///
/// **Needed by any test that mounts the footer**, which since 2026-10-04 is
/// the chooser as well as the front page. `Rodape` reads the counter with no
/// fallback for a missing provider, for the reason [comNovidades] spells out
/// above: a widget that shrugs off an absent provider hides the day a screen
/// genuinely forgets one, and the suite stays green while the page is broken.
///
/// The repository answers an empty body, so the count never resolves and the
/// counter draws nothing — which is exactly what a footer does on a page
/// whose count has not arrived, and keeps the wrapper from putting a number
/// on screen that no test asked for.
Widget comVisitas(Widget child, {String chave = 'portal_pw_teste_visitas'}) =>
    BlocProvider<VisitCounterViewModel>(
      create: (_) => VisitCounterViewModel(
        VisitRepository(
          client: MockClient((_) async => http.Response('[]', 200)),
          memory: BrowserMemory.platform(chave),
        ),
      ),
      child: child,
    );

/// Envolve [child] com um `SearchViewModel` — o terceiro que o `main.dart`
/// monta acima de todas as rotas.
///
/// **Preciso para qualquer tela que leia o índice do mercado**, o que desde
/// 05/10/2026 inclui a das guerras territoriais: os chips de classe tiram dele
/// o número que nomeia a arte, em vez de uma tabela de nomes escrita à mão que
/// divergiria no dia em que o jogo acrescentasse uma classe.
///
/// O índice chega vazio, que é o estado em que a tela desenha os chips só com
/// o nome — exactamente o que acontece enquanto o índice de verdade ainda
/// carrega.
Widget comBusca(Widget child, {Object corpo = const {}}) =>
    BlocProvider<SearchViewModel>(
      create: (_) => SearchViewModel(
        IndexRepository(
          MockClient((_) async => http.Response(jsonEncode(corpo), 200)),
        ),
      )..load(),
      child: child,
    );

/// Envolve [child] com um `AoVivoViewModel` — o quarto que o `main.dart`
/// monta acima de todas as rotas.
///
/// **Necessário desde 09/11/2026 por qualquer teste que monte a raiz**, e não
/// só a home: a faixa de quem está ao vivo passou a desenhar-se também na
/// tela de escolha, para o canal que joga 1.4.4 ter onde aparecer enquanto
/// aquela versão não tem tela própria.
///
/// [canais] são as linhas que o cubit já considera ao vivo — este duplo não
/// chama `aoVivoAgora`, portanto um teste que queira a faixa vazia passa a
/// lista vazia, que é o caso normal e o que a maioria dos testes quer.
Widget comAoVivo(Widget child, {List<CanalAoVivo> canais = const []}) =>
    BlocProvider<AoVivoViewModel>.value(
      value: _AoVivoFixo(canais),
      child: child,
    );

/// Um `AoVivoViewModel` que não fala com a rede e não recalcula nada.
class _AoVivoFixo extends Cubit<List<CanalAoVivo>> implements AoVivoViewModel {
  _AoVivoFixo(super.canais);

  @override
  Future<void> load() async {}
}
