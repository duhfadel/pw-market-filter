import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/roster_view_model.dart';
import 'package:pw_market_filter/features/guild/ui/widgets/jogador_form.dart';

class _FakeFichasRepo implements FichasRepository {
  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      const Success([]);

  @override
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async => const Success<void>(null);
}

class _FakeRepo implements JogadoresRepository {
  _FakeRepo(this._lista);
  final List<Jogador> _lista;

  @override
  Future<Result<List<Jogador>>> lista() async => Success(_lista);

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

/// Edit mode must never let the dialog double as a way to re-target an
/// existing row to a different character — the name is what says which
/// player this is, so it comes in preset and locked.
void main() {
  testWidgets('edit mode shows the current name preset and fixed', (
    tester,
  ) async {
    final vm = RosterViewModel(_FakeRepo([]), _FakeFichasRepo(), Papel.admin);
    final jogador = Jogador(id: '42', nome: 'mozaum', classe: 'Místico');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JogadorForm(vm: vm, inicial: jogador),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The name arrives already filled in from the player being edited.
    expect(find.text('mozaum'), findsOneWidget);
    expect(find.text('Editar jogador'), findsOneWidget);

    // And it cannot be changed to pick a different character: the field is
    // read-only, so typing into it has no effect at all.
    await tester.enterText(
      find.byKey(const Key('campo_nome')),
      'outro personagem',
    );
    await tester.pump();

    expect(find.text('mozaum'), findsOneWidget);
    expect(find.text('outro personagem'), findsNothing);
  });

  testWidgets('add mode (no inicial) still shows the empty, editable form', (
    tester,
  ) async {
    final vm = RosterViewModel(_FakeRepo([]), _FakeFichasRepo(), Papel.admin);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JogadorForm(vm: vm)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adicionar jogador'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo_nome')), 'novato');
    await tester.pump();

    expect(find.text('novato'), findsOneWidget);
  });

  testWidgets('edit mode does not overflow on a narrow phone', (tester) async {
    final vm = RosterViewModel(_FakeRepo([]), _FakeFichasRepo(), Papel.admin);
    final jogador = Jogador(
      id: '42',
      nome: 'umnomebembemlongoparaestourar',
      classe: 'Místico',
      limite: 'Alma Suprema',
      nivel: 105,
      nivelAtaque: 70,
      hp: 55000,
      critico: '32%',
    );

    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JogadorForm(vm: vm, inicial: jogador),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
