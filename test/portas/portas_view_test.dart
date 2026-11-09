import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';
import 'package:pw_market_filter/features/portas/domain/versao.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/widgets/rodape.dart';
import 'package:pw_market_filter/features/portas/ui/portas_view.dart';
import 'package:pw_market_filter/features/portas/ui/widgets/canal_do_portal.dart';
import 'package:pw_market_filter/market/versoes.dart';
import 'package:pw_market_filter/market/versoes_repository.dart';

import '../support/novidades_test_support.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` declares, the way
/// `test/home/cartaz_test.dart` does. `flutter_test` draws every glyph as a
/// square of the font size by default, which fabricates overflows no browser
/// would ever show and would hide a real one just as easily.
Future<void> _carregarFontesReais() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final carregador = FontLoader(familia);
    for (final arquivo in arquivos) {
      carregador.addFont(rootBundle.load(arquivo));
    }
    await carregador.load();
  }

  await carregar('Marcellus', ['assets/fonts/Marcellus-Regular.ttf']);
  await carregar('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
}

VersaoResumo _resumo({
  String chave = 'pw187',
  String nome = '1.8.7',
  int personagens = 1715,
  DateTime? coletadoEm,
  int? novosHoje,
}) => VersaoResumo(
  chave: chave,
  nome: nome,
  personagens: personagens,
  coletadoEm: coletadoEm ?? DateTime.utc(2026, 10, 2, 7, 30),
  novosHoje: novosHoje,
);

/// Every request the fake `versoes.json` endpoint received, so a test can
/// assert what was asked for without caring what answered it.
final _urisPedidas = <Uri>[];

/// Registers `VersoesRepository` in the real `GetIt` instance,
/// `configureDependencies()` never does for the suite, backed by [client] —
/// a network double, never the real one. This is what makes the mount below
/// exercise `getIt<VersoesRepository>().carregar` in
/// `_PortasViewState._carregar`, the only branch production ever runs: before
/// this test registered anything here, every case constructed `PortasView`
/// with its own `carregar:` override, so the `getIt` lookup — unregistered in
/// `injection.dart` — was never once reached, and the `StateError` it threw
/// was silently absorbed by the `unawaited(...)` call in `initState`, leaving
/// the real `/` spinning forever with a green suite on top of it.
void _registrarRepositorio(http.Client client) {
  getIt.registerLazySingleton<VersoesRepository>(
    () => VersoesRepository(client),
  );
}

MockClient _cliente(http.Response Function(http.Request) responder) =>
    MockClient((request) async {
      _urisPedidas.add(request.url);
      return responder(request);
    });

http.Response _corpo(Object json, [int status = 200]) =>
    http.Response(jsonEncode(json), status);

Future<void> _montar(
  WidgetTester tester, {
  List<CanalAoVivo> aoVivo = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            comNovidades(Scaffold(body: Text('rota: ${settings.name}'))),
      ),
      // No `carregar:` override anywhere in this file — `PortasView` has none
      // any more. Every case below reaches `web/versoes.json` only through
      // `getIt<VersoesRepository>()`, registered per-test above.
      home: comAoVivo(
        comVisitas(comNovidades(const PortasView())),
        canais: aoVivo,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The door for [chave] — `'pw187'` or `'pw126'` — and nothing else.
///
/// `Cabecalho`'s own `_Marca` prints the literal text `'1.8.7'` beside the
/// site's mark on every screen, this one included — "the game's own version,
/// not this site's", by its own doc comment. A bare `find.text('1.8.7')`
/// therefore matches that badge too, which has nothing to do with the door
/// under test; scoping every lookup to the door's own key is what keeps this
/// suite about the chooser and not about the header it happens to share with
/// every other screen.
Finder _porta(String chave) => find.byKey(Key('porta-$chave'));

Finder _textoNaPorta(String chave, String texto) =>
    find.descendant(of: _porta(chave), matching: find.text(texto));

Finder _contendoNaPorta(String chave, String trecho) =>
    find.descendant(of: _porta(chave), matching: find.textContaining(trecho));

void main() {
  setUpAll(_carregarFontesReais);

  setUp(() {
    _urisPedidas.clear();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('as duas portas', () {
    testWidgets('both versions collected: both doors show their own facts', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente(
          (_) => _corpo({
            'pw187': _resumo(
              chave: 'pw187',
              nome: '1.8.7',
              personagens: 1715,
              coletadoEm: DateTime.utc(2026, 10, 2, 7, 30),
            ).toJson(),
            'pw126': _resumo(
              chave: 'pw126',
              nome: '1.2.6',
              personagens: 1293,
              coletadoEm: DateTime.utc(2026, 10, 1, 18, 19),
            ).toJson(),
          }),
        ),
      );

      await _montar(tester);

      expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
      expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
      // O número e o rótulo são dois `Text` desde 09/11/2026 — o número
      // grande, a legenda pequena por baixo.
      expect(_textoNaPorta('pw187', '1.715'), findsOneWidget);
      expect(_textoNaPorta('pw126', '1.293'), findsOneWidget);
      expect(_textoNaPorta('pw187', 'personagens à venda'), findsOneWidget);
      // The date is read in local time by `DateTime.toLocal()`, so the test
      // only pins the label — the exact day depends on where this suite runs.
      expect(_contendoNaPorta('pw187', 'coletado em'), findsOneWidget);
      expect(_contendoNaPorta('pw126', 'coletado em'), findsOneWidget);
      // Uma só: o 1.4.4 não lançou e a porta dele diz isso sempre, haja
      // coleta dos outros ou não.
      // **O selo «em breve» saiu a 09/11/2026** junto com as cartas 2:3: na
      // coluna, a descrição do dono já diz quando abre, portanto o selo
      // repetia-a e gastava uma linha numa coluna feita de números. O que
      // diz «ainda não» é o ponto vazado e o esmaecido.
      expect(
        _contendoNaPorta('pw144', 'Abre a 13 de novembro'),
        findsOneWidget,
      );
      expect(_textoNaPorta('pw144', '1.4.4'), findsOneWidget);
    });

    testWidgets('a version with no index yet is dimmed and opens nothing', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      await _montar(tester);

      expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
      expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
      expect(_contendoNaPorta('pw126', 'O mais antigo'), findsOneWidget);
      // The ready door prints its facts; the dimmed one prints none of them.
      expect(_contendoNaPorta('pw187', 'personagens'), findsOneWidget);
      expect(_contendoNaPorta('pw126', 'personagens'), findsNothing);

      final portaFechada = tester.widget<Opacity>(_porta('pw126'));
      expect(portaFechada.opacity, lessThan(1));

      final toqueFechado = tester.widget<InkWell>(
        find.descendant(of: _porta('pw126'), matching: find.byType(InkWell)),
      );
      expect(
        toqueFechado.onTap,
        isNull,
        reason: 'a door with no market yet must not be enterable',
      );

      final portaAberta = tester.widget<Opacity>(_porta('pw187'));
      expect(portaAberta.opacity, 1);
    });

    testWidgets('nenhuma coluna carrega arte, e isso é a troca feita', (
      tester,
    ) async {
      // **Este teste afirmava o contrário até 09/11/2026**, e a mudança é
      // decisão de produto e não conserto. Cada porta vestia um retrato 2:3
      // da sua própria classe, e ele cravava que a arte esmaecia com a porta
      // — nunca uma fotografia acesa sobre uma porta apagada.
      //
      // O raciocínio valia enquanto esta tela era só o garfo. Com o herói a
      // abrir a página com um retrato a toda a altura, três retratos logo
      // abaixo punham **quatro** peças de arte de classe no mesmo ecrã, e a
      // que manda deixava de mandar. A arte saiu das colunas; o esmaecido
      // ficou, e é o que outro caso aqui crava.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      await _montar(tester);

      for (final chave in const ['pw187', 'pw126', 'pw144']) {
        expect(
          find.descendant(of: _porta(chave), matching: find.byType(Image)),
          findsNothing,
          reason: 'a coluna $chave voltou a carregar arte',
        );
      }
    });

    testWidgets("tapping a ready door opens that version's home", (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      // **A porta passou a estar abaixo da dobra a 09/11/2026**, quando a raiz
      // ganhou a abertura por cima dela, e um `tap` num widget fora do ecrã
      // não acerta. `ensureVisible` sozinho não basta: alinha o mínimo, e a
      // porta é um retrato 2:3 mais alto do que o ecrã deixa, portanto o
      // **centro** dela — onde o toque cai — continuava fora, a 751 px num
      // ecrã de 600. Uma janela alta é a resposta certa aqui, porque este
      // teste é sobre a navegação e não sobre o layout, que tem testes
      // próprios.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _montar(tester);

      await tester.ensureVisible(_porta('pw187'));
      await tester.pumpAndSettle();
      await tester.tap(_porta('pw187'));
      await tester.pumpAndSettle();

      expect(find.text('rota: /1.8.7'), findsOneWidget);
    });

    testWidgets(
      'no collection has ever run: both doors still draw, both dimmed — not an error screen',
      (tester) async {
        _registrarRepositorio(_cliente((_) => http.Response('', 404)));

        await _montar(tester);

        expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
        expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
        // Sem coleta nenhuma, as três ficam esmaecidas e com a descrição
        // delas — que é o que a coluna tem para dizer quando não tem número.
        expect(tester.widget<Opacity>(_porta('pw187')).opacity, 0.5);
        expect(tester.widget<Opacity>(_porta('pw126')).opacity, 0.5);
        expect(_contendoNaPorta('pw187', 'Aberto em junho'), findsOneWidget);
        expect(_contendoNaPorta('pw126', 'O mais antigo'), findsOneWidget);
        expect(find.textContaining('Não deu para carregar'), findsNothing);
      },
    );

    testWidgets(
      'the file existing and failing to parse is a real error, not a blank screen',
      (tester) async {
        _registrarRepositorio(
          _cliente((_) => http.Response('não é json', 200)),
        );

        await _montar(tester);

        expect(_porta('pw187'), findsNothing);
        expect(_porta('pw126'), findsNothing);
        expect(find.textContaining('Não deu para carregar'), findsOneWidget);
      },
    );

    testWidgets(
      'the registration missing from GetIt is a real error too, never an '
      'eternal spinner',
      (tester) async {
        // No `_registrarRepositorio` call at all — the exact shape of B1:
        // `getIt<VersoesRepository>()` throws `StateError` because nothing
        // registered it. Before the `try`/`catch` in `_carregar`, that throw
        // escaped the `unawaited` call in `initState` unseen, `setState` was
        // never reached, and the screen stayed in `_Carregando` forever.
        await _montar(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Não deu para carregar'), findsOneWidget);
      },
    );

    testWidgets('the chooser never fetches either market index', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      await _montar(tester);

      expect(_urisPedidas, isNotEmpty);
      for (final uri in _urisPedidas) {
        expect(uri.path, endsWith('versoes.json'));
        expect(uri.path, isNot(contains('market_index')));
      }
    });

    testWidgets('no number on the doors is drawn in the display face', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente(
          (_) => _corpo({
            'pw187': _resumo(
              chave: 'pw187',
              nome: '1.8.7',
              personagens: 1715,
              coletadoEm: DateTime.utc(2026, 10, 2),
            ).toJson(),
          }),
        ),
      );

      await _montar(tester);

      final nomeDaPorta = tester.widget<Text>(_textoNaPorta('pw187', '1.8.7'));
      expect(
        nomeDaPorta.style?.fontFamily,
        isNot(PWTheme.display),
        reason:
            'Marcellus draws Roman figures: its 1 has no flag and its 0 is '
            'barely an O',
      );

      // O número, que é o algarismo que mais importa não sair como `I.8.7`.
      final contagem = tester.widget<Text>(_contendoNaPorta('pw187', '1.715'));
      expect(contagem.style?.fontFamily, isNot(PWTheme.display));

      final data = tester.widget<Text>(
        _contendoNaPorta('pw187', 'coletado em'),
      );
      expect(data.style?.fontFamily, isNot(PWTheme.display));
    });
  });

  testWidgets('o rodapé diz de quem é o site, na página que estranhos veem', (
    tester,
  ) async {
    // O seletor passou a ser a porta de entrada, e era a única tela que não
    // dizia nada sobre o que este site é. A primeira frase do rodapé é a
    // linha em que a permissão para existir assenta — e quem chega de um link
    // colado na comunidade aterra aqui, não na home.
    _registrarRepositorio(
      _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
    );
    await _montar(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Projeto de fã'), findsOneWidget);
    expect(
      find.textContaining('Nomes, atributos e arte do jogo'),
      findsOneWidget,
    );
  });

  // **Montado como a app monta, e não com um `Cabecalho` solto.**
  //
  // O primeiro teste desta regra ficou em `cabecalho_versao_test` e provava
  // só que o widget obedece a `semMercado`. Trocando `semMercado: true` por
  // `false` aqui no seletor, ele continuava verde — porque injetava a flag em
  // vez de a deixar a produção resolver. É a mesma forma que custou a tela de
  // escolha inteira a 02/10/2026: *um fake injetado prova a lógica e nada diz
  // sobre a montagem, e é a montagem que quebra.*
  //
  // Por isso este vive aqui, no ecrã real, e falha se alguém deixar de passar
  // a flag.
  testWidgets('o seletor não oferece porta nenhuma de mercado', (tester) async {
    _registrarRepositorio(
      _cliente(
        (_) => _corpo({
          'pw187': _resumo(chave: 'pw187', nome: '1.8.7').toJson(),
          'pw126': _resumo(chave: 'pw126', nome: '1.2.6').toJson(),
        }),
      ),
    );
    await _montar(tester);

    for (final secao in secoesDaHome) {
      final podeAparecer = secaoServeSemMercado(secao);
      expect(
        find.text(secao),
        podeAparecer ? findsOneWidget : findsNothing,
        reason: podeAparecer
            ? 'A secção $secao não leva a rota com versão nenhuma: todas as '
                  'entradas dela são páginas do site ou rotas sem prefixo.'
            : 'A secção $secao leva a uma rota com versão, e nesta tela a '
                  'versão ainda não foi escolhida — clicar escolheria por '
                  'quem clicou.',
      );
    }
    // Novidades fica: lê as mesmas mensagens para os dois mercados.
    expect(find.text('Novidades'), findsOneWidget);
    // E os *Guias* entraram a 09/11/2026, quando as multi contas perderam o
    // prefixo e a secção deixou de ter uma única entrada presa a um mercado.
    expect(find.text('Guias'), findsOneWidget);
  });

  // **Toda porta diz o que é aquele servidor, e isso e desenhado no ecra.**
  //
  // A tela pergunta *qual mercado* e ate 28/10/2026 so respondia com numeros:
  // quantos personagens ha a venda e quando foi a coleta. Isso diz o tamanho
  // da loja e nao diz nada sobre o jogo la dentro, que e a unica coisa que um
  // visitante novo precisa para decidir.
  //
  // Montado no ecra real, pela licao do mesmo dia: injectar a descricao
  // provaria que o card a sabe desenhar e nada diria sobre o modelo a ter.
  testWidgets('cada porta mostra a descrição do servidor', (tester) async {
    _registrarRepositorio(
      _cliente(
        (_) => _corpo({
          'pw187': _resumo(chave: 'pw187', nome: '1.8.7').toJson(),
          'pw126': _resumo(chave: 'pw126', nome: '1.2.6').toJson(),
        }),
      ),
    );
    await _montar(tester);

    for (final porta in portasDe(const {})) {
      expect(
        porta.descricao.trim(),
        isNotEmpty,
        reason: 'A porta ${porta.nome} nasceu sem descrição',
      );
      // O começo da frase, e nao ela inteira: o card corta em quatro linhas,
      // e cravar o texto todo faria este teste reprovar uma frase mais longa
      // que continua a desenhar bem.
      final comeco = porta.descricao.split(',').first;
      expect(
        find.textContaining(comeco, findRichText: true),
        findsOneWidget,
        reason: 'A descrição da porta ${porta.nome} não chegou à tela',
      );
    }
  });

  group('o número que muda sozinho', () {
    testWidgets('a porta diz quantos entraram hoje', (tester) async {
      // Até 09/11/2026 a porta dizia o tamanho da loja e a data da coleta —
      // dois números que mudam de semana a semana. Escolher mercado era um
      // clique que não informava.
      _registrarRepositorio(
        _cliente(
          (_) => _corpo({
            'pw187': _resumo(personagens: 2953, novosHoje: 197).toJson(),
          }),
        ),
      );
      await _montar(tester);

      // **O número e o rótulo são dois `Text` desde 09/11/2026**: na coluna
      // o número é grande e a legenda pequena por baixo, portanto procurar a
      // frase inteira não acha nada.
      expect(find.text('2.953'), findsOneWidget);
      expect(find.text('personagens à venda'), findsOneWidget);
      expect(find.text('197 entraram hoje'), findsOneWidget);
    });

    testWidgets('um ficheiro anterior ao campo não desenha linha nenhuma', (
      tester,
    ) async {
      // Os `versoes.json` já publicados não têm a chave. Lida como zero, a
      // porta anunciaria um mercado parado onde o que há é um ficheiro velho.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      expect(find.textContaining('entraram hoje'), findsNothing);
      expect(find.textContaining('entrou hoje'), findsNothing);
      expect(find.textContaining('ninguém novo'), findsNothing);
      // E o resto da porta continua lá: a ausência de um número não apaga os
      // outros.
      expect(find.text('1.715'), findsOneWidget);
    });

    testWidgets('zero desenha, porque zero é notícia', (tester) async {
      // Num mercado que se move de meia em meia hora, um dia sem ninguém
      // novo é informação — e é o oposto de uma linha velha.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo(novosHoje: 0).toJson()})),
      );
      await _montar(tester);

      expect(find.text('ninguém novo hoje'), findsOneWidget);
    });

    testWidgets('um só não diz «1 entraram»', (tester) async {
      // Com o mercado a crescer 17% em duas semanas, o dia de um só anúncio
      // novo existe — e `1 entraram` lê-se como avaria.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo(novosHoje: 1).toJson()})),
      );
      await _montar(tester);

      expect(find.text('1 entrou hoje'), findsOneWidget);
    });

    testWidgets('a porta que ainda não abriu não ganha número', (tester) async {
      // O 1.4.4 não tem índice nenhum, portanto não tem linha em
      // `versoes.json` — e `em breve` é o que a porta diz em vez de um zero
      // que leria como mercado vazio.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo(novosHoje: 197).toJson()})),
      );
      await _montar(tester);

      expect(tester.widget<Opacity>(_porta('pw144')).opacity, 0.5);
      expect(find.textContaining('entraram hoje'), findsOneWidget);
    });
  });

  group('a faixa de quem está ao vivo, na raiz', () {
    CanalAoVivo canal(String nome, String? titulo) => CanalAoVivo(
      canal: nome.toLowerCase(),
      nome: nome,
      aoVivo: true,
      titulo: titulo,
      jogo: 'Perfect World',
      espectadores: 10,
      vistoEm: DateTime.now(),
    );

    testWidgets('o canal do 1.4.4 aparece aqui, que é o pedido do dono', (
      tester,
    ) async {
      // Ele não tem tela própria ainda, e as duas que têm faixa recusam-no
      // com razão — portanto esta é a única tela do site onde ele cabe.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(
        tester,
        aoVivo: [canal('Magraotvv', 'THE CLASSIC PW 1.4.4 BETA ABERTO')],
      );

      expect(find.text('Magraotvv'), findsOneWidget);
    });

    testWidgets('quem não escreve versão nenhuma também aparece', (
      tester,
    ) async {
      // A raiz não é de versão nenhuma, portanto não afirma nada ao
      // mostrá-lo — o contrário exacto de uma página de versão.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(
        tester,
        aoVivo: [canal('SemVersao', 'Perfect World com os amigos')],
      );

      expect(find.text('SemVersao'), findsOneWidget);
    });

    testWidgets('ninguém ao vivo não abre vão nenhum', (tester) async {
      // O espaço acima da faixa é desenhado por dentro dela de propósito:
      // posto por fora ficaria a abrir um vão sobre nada, que é o caso
      // normal — oito canais offline foi o que a tabela respondeu a 09/11.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      expect(find.text('STREAMERS AMIGOS'), findsNothing);
    });

    testWidgets('no telemóvel a faixa rola com a página, sem transbordar', (
      tester,
    ) async {
      // O ramo empilhado é outro desenho: ali o rodapé é o fim da página e
      // rola com ela, porque duas cartas 2:3 não cabem em telemóvel nenhum.
      // Uma secção nova tem de caber nos dois ramos, e este é o que o teste
      // de 800 px de largura nunca exercita.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester, aoVivo: [canal('Magraotvv', 'pw 1.4.4 beta')]);

      expect(tester.takeException(), isNull);
      expect(find.text('STREAMERS AMIGOS'), findsOneWidget);
    });

    testWidgets('o rodapé fica no fim da página e alcança-se rolando', (
      tester,
    ) async {
      // **Este teste mudou de afirmação a 09/11/2026**, e é o desenho que
      // mudou e não o código que quebrou. O rodapé estava pregado em baixo no
      // caso largo, portanto cravar que ele cabia no ecrã era a asserção
      // certa; com a abertura por cima e três secções abaixo a página rola
      // sempre, e um rodapé que caiba no ecrã passaria a querer dizer uma
      // página sem conteúdo.
      //
      // O que continua a valer é que ele existe, que se alcança, e que nada
      // transborda pelo caminho — o defeito real que a versão anterior
      // procurava.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester, aoVivo: [canal('Magraotvv', 'pw 1.4.4 beta')]);

      expect(tester.takeException(), isNull);
      expect(find.byType(Rodape), findsOneWidget);
      await tester.ensureVisible(find.byType(Rodape));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('a abertura: a raiz deixou de ser torniquete', () {
    testWidgets('diz o que o site faz antes de dizer o nome dele', (
      tester,
    ) async {
      // Eram três cartas e 148 palavras, e foi esta a página que o AdSense
      // viu como vazia a 31/10/2026.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      expect(find.text('As contas que o jogo não faz'), findsOneWidget);
      // A manchete é do herói, em Marcellus sobre a arte; a secção abaixo
      // responde outra pergunta — *o que é isto que vou ver números sobre*.
      expect(find.text('Três versões, três mercados'), findsOneWidget);
      expect(
        find.textContaining('vender o personagem inteiro'),
        findsOneWidget,
      );
    });

    testWidgets('a premissa não publica preço nenhum', (tester) async {
      // Um número do jogo é permanente e um preço de mercado não é. A
      // primeira versão desta prosa dizia «a de 70 vende por 1000 TCC e as de
      // 40 por 90», copiado de uma medição de Agosto — e a 09/11 as faixas já
      // se sobrepunham. Os números que se movem ficam nas portas, com a data
      // da coleta ao lado.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      // Varre a página inteira e não só a premissa: o único TCC que pode
      // aparecer na raiz é dentro de uma porta, e as portas não escrevem
      // preço nenhum — dizem quantos personagens há.
      final textos = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(textos, isNot(contains('TCC')));
    });

    testWidgets('a abertura vem antes das portas, nunca depois', (
      tester,
    ) async {
      // É a ordem que o dono pediu: «talvez falte a informaçao antes do
      // market para que o pessoal entenda o que sao aqueles numeros».
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      final heroi = tester.getTopLeft(
        find.text('As contas que o jogo não faz'),
      );
      final porta = tester.getTopLeft(_porta('pw126'));
      expect(heroi.dy, lessThan(porta.dy));
    });

    testWidgets('a banda do canal está na árvore da raiz', (tester) async {
      // **Montada, e não só testada sozinha.** A banda busca os vídeos pela
      // rede, portanto o que ela desenha vive no teste dela; o que vive aqui
      // é a ligação — a secção existir nesta tela e em nenhuma de versão,
      // porque o canal é do site e não de um mercado.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      expect(find.byType(CanalDoPortal), findsOneWidget);
    });

    testWidgets('os guias das três versões, cada um com a sua à vista', (
      tester,
    ) async {
      // Aqui a etiqueta de versão é a informação que falta — ao contrário de
      // uma tela de versão, onde seria ruído em sete de oito cartas.
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );
      await _montar(tester);

      expect(find.text('TODOS OS GUIAS'), findsOneWidget);
      expect(find.text('todas as versões'), findsOneWidget);
    });
  });
}
