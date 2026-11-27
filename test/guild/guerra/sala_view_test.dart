import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/formacao_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/grupo_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/membro_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/sala_view.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/sala_view_model.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/widgets/chip_jogador.dart';

import '../../support/load_fonts.dart';

class _FakeFormacaoRepository implements FormacaoRepository {
  _FakeFormacaoRepository(this._formacao, {this.falhaAoSalvar = false});
  final FormacaoGuerra _formacao;
  final bool falhaAoSalvar;
  FormacaoGuerra? salva;

  @override
  Future<Result<FormacaoGuerra>> carregar() async => Success(_formacao);

  @override
  Future<Result<void>> salvar(FormacaoGuerra f) async {
    if (falhaAoSalvar) return const Failure(GuildFailure(GuildErro.salvar));
    salva = f;
    return const Success<void>(null);
  }
}

class _FakeJogadoresRepository implements JogadoresRepository {
  _FakeJogadoresRepository(this._jogadores);
  final List<Jogador> _jogadores;

  @override
  Future<Result<List<Jogador>>> lista() async => Success(_jogadores);

  @override
  Future<Result<void>> criar(Jogador j) async => const Success<void>(null);

  @override
  Future<Result<String>> subirPrint(
    Uint8List bytes,
    String nomeArquivo,
  ) async => Success(nomeArquivo);

  @override
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async =>
      const Success<void>(null);
}

Jogador _jogador(String id, String nome, {String? classe, int? nivelAtaque}) =>
    Jogador(
      id: id,
      nome: nome,
      classe: classe,
      nivelAtaque: nivelAtaque,
      status: 'transcrito',
    );

/// Registers a fresh [SalaGuerrasViewModel] factory for the fakes given —
/// `SalaGuerrasView` reads it straight out of `getIt`, exactly as
/// `injection.dart`'s own registration does in production.
void _registrar(
  FormacaoRepository formacaoRepo,
  JogadoresRepository jogadoresRepo,
) {
  getIt.registerFactory<SalaGuerrasViewModel>(
    () => SalaGuerrasViewModel(formacaoRepo, jogadoresRepo),
  );
}

void main() {
  // Real fonts, not the harness's square-per-glyph stand-in — this screen's
  // own overflow tests need the true width of a chip's name and NA label.
  setUpAll(loadAppFonts);

  tearDown(() {
    if (getIt.isRegistered<SalaGuerrasViewModel>()) {
      getIt.unregister<SalaGuerrasViewModel>();
    }
  });

  FormacaoGuerra formacaoComUmMembro() => FormacaoGuerra(
    grupos: [
      GrupoGuerra(
        nome: 'Pt 1',
        cor: '#56A8F5',
        membros: [MembroGuerra(jogadorId: 'a')],
      ),
    ],
  );

  List<Jogador> jogadores() => [
    _jogador('a', 'Aaron', classe: 'Guerreiro', nivelAtaque: 70),
    _jogador('b', 'Bruno', classe: 'Mago', nivelAtaque: 50),
  ];

  testWidgets('shows the placed member in the pt and the rest in the pool', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    expect(find.text('Pt 1'), findsOneWidget);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('Aaron'), findsOneWidget);
    expect(find.text('Disponíveis (1)'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
  });

  testWidgets('tapping the crown toggles leadership and tints it', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    final coroa = find.text('♛');
    expect(coroa, findsOneWidget);
    expect(
      (tester.widget(coroa) as Text).style?.color,
      isNot(const Color(0xFF56A8F5)),
    );

    await tester.tap(coroa);
    await tester.pumpAndSettle();

    expect(
      (tester.widget(coroa) as Text).style?.color,
      const Color(0xFF56A8F5),
    );
  });

  testWidgets('removing a member from a pt sends them back to the pool', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('✕'));
    await tester.pumpAndSettle();

    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('Arraste jogadores para cá.'), findsOneWidget);
    expect(find.text('Disponíveis (2)'), findsOneWidget);
  });

  testWidgets('renaming a pt through the dialog updates its header', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Renomear'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Linha de frente');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Linha de frente'), findsOneWidget);
    expect(find.text('Pt 1'), findsNothing);
  });

  testWidgets('recolouring a pt through the palette updates its swatch', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('swatch_pt_0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cor_#FF5C5C')));
    await tester.pumpAndSettle();

    final crown = tester.widget<Text>(find.text('♛'));
    expect(crown.style?.color, isNot(const Color(0xFF56A8F5)));
  });

  testWidgets('"+ nova pt" adds an empty group', (tester) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nova_pt')));
    await tester.pumpAndSettle();

    expect(find.text('Pt 2'), findsOneWidget);
  });

  testWidgets('a failed save shows the typed error on a snackbar', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro(), falhaAoSalvar: true),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar formação'));
    await tester.pumpAndSettle();

    expect(find.text('Não deu para salvar.'), findsOneWidget);
  });

  testWidgets('a successful save updates the "last saved" label', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    expect(find.text('ainda não salvo'), findsOneWidget);

    await tester.tap(find.text('Salvar formação'));
    await tester.pumpAndSettle();

    expect(find.text('salvo agora'), findsOneWidget);
  });

  testWidgets('a crowded board does not overflow on a narrow phone', (
    tester,
  ) async {
    final muitosJogadores = [
      for (var i = 0; i < 14; i++)
        _jogador(
          'j$i',
          'Jogador Com Nome Bem Longo $i',
          classe: 'Bardo',
          nivelAtaque: 70,
        ),
    ];
    final formacao = FormacaoGuerra(
      grupos: [
        for (var g = 0; g < 3; g++)
          GrupoGuerra(
            nome: 'Pt ${g + 1} de linha de frente',
            cor: '#56A8F5',
            membros: [
              for (
                var i = g * 4;
                i < g * 4 + 4 && i < muitosJogadores.length;
                i++
              )
                MembroGuerra(jogadorId: 'j$i'),
            ],
          ),
      ],
    );
    _registrar(
      _FakeFormacaoRepository(formacao),
      _FakeJogadoresRepository(muitosJogadores),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a crowded board does not overflow on a wide desktop window', (
    tester,
  ) async {
    final muitosJogadores = [
      for (var i = 0; i < 14; i++)
        _jogador(
          'j$i',
          'Jogador Com Nome Bem Longo $i',
          classe: 'Bardo',
          nivelAtaque: 70,
        ),
    ];
    final formacao = FormacaoGuerra(
      grupos: [
        for (var g = 0; g < 6; g++)
          GrupoGuerra(
            nome: 'Pt ${g + 1} de linha de frente',
            cor: '#56A8F5',
            membros: [
              for (
                var i = g * 2;
                i < g * 2 + 2 && i < muitosJogadores.length;
                i++
              )
                MembroGuerra(jogadorId: 'j$i'),
            ],
          ),
      ],
    );
    _registrar(
      _FakeFormacaoRepository(formacao),
      _FakeJogadoresRepository(muitosJogadores),
    );

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('SalaGuerrasView wires its own Cubit through BlocProvider', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(context.read<SalaGuerrasViewModel>(), isA<SalaGuerrasViewModel>());
  });

  /// Drags the named player's handle (`⠿`) from wherever it currently sits
  /// to `destino`, one step at a time — mirroring
  /// `instancias_view_test.dart`'s own "arrastar um personagem" drag, since
  /// this screen's `_Pega` is the same `Draggable` shape.
  Future<void> arrastar(
    WidgetTester tester,
    String jogador,
    Offset destino,
  ) async {
    final chip = find.ancestor(
      of: find.text(jogador),
      matching: find.byType(ChipJogador),
    );
    final pega = tester.getCenter(
      find.descendant(of: chip, matching: find.text('⠿')),
    );
    final gesto = await tester.startGesture(pega);
    await tester.pump();
    for (var i = 1; i <= 8; i++) {
      await gesto.moveTo(Offset.lerp(pega, destino, i / 8)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesto.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a pool chip onto a pt by its handle places them', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    final alvo = tester.getCenter(find.text('Pt 1'));
    await arrastar(tester, 'Bruno', alvo);

    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('Disponíveis (0)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pt_0')),
        matching: find.text('Bruno'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dragging a member onto the pool by its handle removes them', (
    tester,
  ) async {
    _registrar(
      _FakeFormacaoRepository(formacaoComUmMembro()),
      _FakeJogadoresRepository(jogadores()),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    final alvo = tester.getCenter(find.text('Disponíveis (1)'));
    await arrastar(tester, 'Aaron', alvo);

    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('Disponíveis (2)'), findsOneWidget);
    expect(find.text('Arraste jogadores para cá.'), findsOneWidget);
  });

  testWidgets('dropping onto a full pt does not move the dragged player', (
    tester,
  ) async {
    final cheios = [
      for (var i = 0; i < 10; i++) _jogador('m$i', 'Membro $i'),
      _jogador('extra', 'Extra'),
    ];
    final formacao = FormacaoGuerra(
      grupos: [
        GrupoGuerra(
          nome: 'Pt 1',
          cor: '#56A8F5',
          membros: [
            for (var i = 0; i < 10; i++) MembroGuerra(jogadorId: 'm$i'),
          ],
        ),
      ],
    );
    _registrar(
      _FakeFormacaoRepository(formacao),
      _FakeJogadoresRepository(cheios),
    );

    await tester.pumpWidget(const MaterialApp(home: SalaGuerrasView()));
    await tester.pumpAndSettle();

    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('Disponíveis (1)'), findsOneWidget);

    final alvo = tester.getCenter(find.text('Pt 1'));
    await arrastar(tester, 'Extra', alvo);

    // The full group refused the drop — nothing moved.
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('Disponíveis (1)'), findsOneWidget);
  });
}
