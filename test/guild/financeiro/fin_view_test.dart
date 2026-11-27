import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/financeiro_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/fin_view.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/fin_view_model.dart';

import '../../support/load_fonts.dart';

class _FakeFinanceiroRepository implements FinanceiroRepository {
  _FakeFinanceiroRepository(this._lancamentos);
  List<Lancamento> _lancamentos;
  bool falhaAoAdicionar = false;
  bool falhaAoRemover = false;
  Lancamento? adicionado;
  String? removido;

  @override
  Future<Result<List<Lancamento>>> lista() async => Success(_lancamentos);

  @override
  Future<Result<void>> adicionar(Lancamento l) async {
    if (falhaAoAdicionar) return const Failure(GuildFailure(GuildErro.salvar));
    adicionado = l;
    _lancamentos = [..._lancamentos, l];
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> remover(String id) async {
    if (falhaAoRemover) return const Failure(GuildFailure(GuildErro.salvar));
    removido = id;
    _lancamentos = _lancamentos.where((l) => l.id != id).toList();
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

Lancamento _lanc({
  required String id,
  required TipoLancamento tipo,
  Pote pote = Pote.caixa,
  Pote? poteDestino,
  required int valor,
  CategoriaEntrada? categoria,
  String? descricao,
  String? membro,
  bool fixo = false,
}) => Lancamento(
  id: id,
  tipo: tipo,
  pote: pote,
  poteDestino: poteDestino,
  valor: valor,
  categoria: categoria,
  descricao: descricao,
  membro: membro,
  fixo: fixo,
  data: DateTime(2026, 11, 27),
);

Jogador _jogador(String id, String nome) =>
    Jogador(id: id, nome: nome, status: 'transcrito');

/// Registers a fresh [FinanceiroViewModel] factory for the fakes given —
/// `FinanceiroView` reads it straight out of `getIt`, exactly as
/// `injection.dart`'s own registration does in production.
_FakeFinanceiroRepository _registrar({
  List<Lancamento> lancamentos = const [],
  List<Jogador> jogadores = const [],
}) {
  final finRepo = _FakeFinanceiroRepository(lancamentos);
  getIt.registerFactory<FinanceiroViewModel>(
    () => FinanceiroViewModel(finRepo, _FakeJogadoresRepository(jogadores)),
  );
  return finRepo;
}

void main() {
  // Real fonts — this screen's own overflow tests need the true width of a
  // ledger row's name and a dialog's chip labels.
  setUpAll(loadAppFonts);

  tearDown(() {
    if (getIt.isRegistered<FinanceiroViewModel>()) {
      getIt.unregister<FinanceiroViewModel>();
    }
  });

  testWidgets('shows the total, both pots and the ledger rows', (tester) async {
    _registrar(
      lancamentos: [
        _lanc(
          id: 'e1',
          tipo: TipoLancamento.entrada,
          valor: 1000,
          categoria: CategoriaEntrada.guildAtiva,
        ),
        _lanc(
          id: 'd1',
          tipo: TipoLancamento.despesa,
          valor: 200,
          descricao: 'Site',
        ),
        _lanc(
          id: 't1',
          tipo: TipoLancamento.transferencia,
          pote: Pote.caixa,
          poteDestino: Pote.reserva,
          valor: 300,
        ),
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    // total = 1000 - 200 (the transfer never touches it); caixa and reserva
    // split what is left between them.
    expect(find.text('800 TCC'), findsOneWidget);
    expect(find.text('500 TCC'), findsOneWidget);
    expect(find.text('300 TCC'), findsWidgets);

    // The chart above the ledger pushes the rows past the first screenful,
    // and the sliver list only builds what is near the viewport — scroll
    // there before asserting on anything the list itself draws.
    await tester.scrollUntilVisible(find.text('Site'), 300);

    expect(find.text('+1.000 TCC'), findsOneWidget);
    expect(find.text('-200 TCC'), findsOneWidget);
    expect(find.text('Caixa → Reserva'), findsOneWidget);
    expect(find.text('Site'), findsOneWidget);
    expect(find.text('Guilda ativa'), findsOneWidget);
  });

  testWidgets('adding an entrada through the dialog updates the ledger', (
    tester,
  ) async {
    final repo = _registrar();

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar dinheiro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo_valor')), '500');
    await tester.tap(find.byKey(const Key('pote_reserva')));
    await tester.tap(find.byKey(const Key('categoria_territorio')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirmar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.adicionado?.tipo, TipoLancamento.entrada);
    expect(repo.adicionado?.pote, Pote.reserva);
    expect(repo.adicionado?.categoria, CategoriaEntrada.territorio);
    expect(repo.adicionado?.valor, 500);
    // The chart above the ledger pushes the new row past the first
    // screenful — scroll to it before asserting it is there.
    await tester.scrollUntilVisible(find.text('+500 TCC'), 300);
    expect(find.text('+500 TCC'), findsOneWidget);
    // Reserva's own card now reads 500 too.
    expect(find.text('500 TCC'), findsWidgets);
  });

  testWidgets(
    'the despesa dialog keeps "Adicionar" disabled without a description',
    (tester) async {
      _registrar();

      await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar despesa'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_valor')), '100');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirmar')))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('campo_descricao')),
        'Hospedagem',
      );
      await tester.tap(find.byKey(const Key('fixo')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirmar')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'pagar staff resolves the chosen jogador to a name in the ledger',
    (tester) async {
      final repo = _registrar(
        jogadores: [_jogador('a', 'Aaron'), _jogador('b', 'Bruno')],
      );

      await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pagar staff'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_valor')), '300');
      await tester.tap(find.byKey(const Key('campo_membro')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmar')));
      await tester.pumpAndSettle();

      expect(repo.adicionado?.tipo, TipoLancamento.pagamentoStaff);
      expect(repo.adicionado?.membro, 'b');
      // The chart above the ledger pushes the new row past the first
      // screenful — scroll to it before asserting it is there.
      await tester.scrollUntilVisible(find.text('Bruno'), 300);
      expect(find.text('Bruno'), findsOneWidget);
      // Found more than once: the pot and total cards now read the same
      // negative figure as the ledger row itself.
      expect(find.text('-300 TCC'), findsWidgets);
    },
  );

  testWidgets('transferir flips the destino label and sends pote/poteDestino', (
    tester,
  ) async {
    final repo = _registrar();

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transferir'));
    await tester.pumpAndSettle();

    final destino = find.byKey(const Key('transferencia_destino'));
    expect(tester.widget<Text>(destino).data, 'Reserva');

    await tester.tap(find.byKey(const Key('pote_reserva')));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(destino).data, 'Caixa');

    await tester.enterText(find.byKey(const Key('campo_valor')), '400');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar')));
    await tester.pumpAndSettle();

    expect(repo.adicionado?.tipo, TipoLancamento.transferencia);
    expect(repo.adicionado?.pote, Pote.reserva);
    expect(repo.adicionado?.poteDestino, Pote.caixa);
    expect(repo.adicionado?.valor, 400);
  });

  testWidgets('removing a lançamento asks for confirmation first', (
    tester,
  ) async {
    final repo = _registrar(
      lancamentos: [
        _lanc(
          id: 'x1',
          tipo: TipoLancamento.despesa,
          valor: 50,
          descricao: 'Taxa',
        ),
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    // The chart above the ledger pushes the row past the first screenful —
    // scroll to its button before tapping it.
    await tester.scrollUntilVisible(
      find.byKey(const Key('remover_lancamento')),
      300,
    );
    await tester.tap(find.byKey(const Key('remover_lancamento')));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.removido, isNull);
    expect(find.text('Taxa'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remover_lancamento')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar_remocao')));
    await tester.pumpAndSettle();

    expect(repo.removido, 'x1');
    expect(find.text('Taxa'), findsNothing);
    expect(find.text('Nenhum lançamento ainda.'), findsOneWidget);
  });

  testWidgets('a write failure closes the dialog and shows the snackbar', (
    tester,
  ) async {
    final repo = _registrar();
    repo.falhaAoAdicionar = true;

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar dinheiro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_valor')), '100');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Não deu para salvar.'), findsOneWidget);
  });

  testWidgets('a long description does not overflow on a phone-width screen', (
    tester,
  ) async {
    _registrar(
      lancamentos: [
        _lanc(
          id: 'd1',
          tipo: TipoLancamento.despesa,
          valor: 1234567,
          descricao:
              'Uma descrição bem longa que não deveria quebrar o layout '
              'da linha do livro-caixa de forma alguma',
          fixo: true,
        ),
        _lanc(
          id: 'p1',
          tipo: TipoLancamento.pagamentoStaff,
          valor: 999,
          membro: 'a',
        ),
      ],
      jogadores: [
        _jogador('a', 'Um Jogador Com Um Nome Bastante Longo Também'),
      ],
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FinanceiroView()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
