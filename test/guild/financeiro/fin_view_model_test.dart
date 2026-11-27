import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/financeiro_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/fin_estado.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/fin_view_model.dart';

class _FakeFinanceiroRepository implements FinanceiroRepository {
  _FakeFinanceiroRepository(this._lancamentos);
  List<Lancamento> _lancamentos;
  bool falhaAoListar = false;
  bool falhaAoAdicionar = false;
  bool falhaAoRemover = false;
  Lancamento? adicionado;
  String? removido;

  @override
  Future<Result<List<Lancamento>>> lista() async {
    if (falhaAoListar) return const Failure(GuildFailure(GuildErro.carregar));
    return Success(_lancamentos);
  }

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
  bool falhaAoListar = false;

  @override
  Future<Result<List<Jogador>>> lista() async {
    if (falhaAoListar) return const Failure(GuildFailure(GuildErro.carregar));
    return Success(_jogadores);
  }

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

Jogador _jogador(String id) => Jogador(id: id, nome: 'Jogador $id');

Lancamento _lancamento({
  String id = 'l1',
  TipoLancamento tipo = TipoLancamento.entrada,
  Pote pote = Pote.caixa,
  Pote? poteDestino,
  int valor = 1000,
}) => Lancamento(
  id: id,
  tipo: tipo,
  pote: pote,
  poteDestino: poteDestino,
  valor: valor,
  data: DateTime(2026, 11, 27),
);

/// Entrada de 1000 no caixa, despesa de 200 no caixa, e uma transferência de
/// 300 do caixa para a reserva — o caso que exercita os três ramos de
/// `saldoDoPote` numa só lista.
List<Lancamento> _ledgerComTransferencia() => [
  _lancamento(id: 'l1', tipo: TipoLancamento.entrada, valor: 1000),
  _lancamento(id: 'l2', tipo: TipoLancamento.despesa, valor: 200),
  _lancamento(
    id: 'l3',
    tipo: TipoLancamento.transferencia,
    valor: 300,
    poteDestino: Pote.reserva,
  ),
];

void main() {
  group('carregar', () {
    test(
      'emits FinPronto with the right saldoCaixa/saldoReserva/totalGuild',
      () async {
        final vm = FinanceiroViewModel(
          _FakeFinanceiroRepository(_ledgerComTransferencia()),
          _FakeJogadoresRepository([_jogador('a')]),
        );

        await vm.carregar();

        final s = vm.state;
        expect(s, isA<FinPronto>());
        final pronto = s as FinPronto;
        expect(pronto.saldoCaixa, 500); // 1000 - 200 - 300
        expect(pronto.saldoReserva, 300);
        expect(pronto.totalGuild, 800); // unaffected by the transfer
        expect(pronto.jogadores.map((j) => j.id), ['a']);
      },
    );

    test('a failure loading either side emits FinFalha', () async {
      final financeiroRepo = _FakeFinanceiroRepository(
        _ledgerComTransferencia(),
      )..falhaAoListar = true;
      final vm = FinanceiroViewModel(
        financeiroRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );

      await vm.carregar();

      expect(vm.state, isA<FinFalha>());
    });

    test('a failure loading the roster also emits FinFalha', () async {
      final jogadoresRepo = _FakeJogadoresRepository([
        _jogador('a'),
      ])..falhaAoListar = true;
      final vm = FinanceiroViewModel(
        _FakeFinanceiroRepository(_ledgerComTransferencia()),
        jogadoresRepo,
      );

      await vm.carregar();

      expect(vm.state, isA<FinFalha>());
    });
  });

  group('adicionar', () {
    test('calls the repository and reloads with the new entry', () async {
      final financeiroRepo = _FakeFinanceiroRepository(
        _ledgerComTransferencia(),
      );
      final vm = FinanceiroViewModel(
        financeiroRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );
      await vm.carregar();
      final novo = _lancamento(id: 'l4', tipo: TipoLancamento.entrada, valor: 50);

      await vm.adicionar(novo);

      expect(financeiroRepo.adicionado, same(novo));
      final s = vm.state as FinPronto;
      expect(s.lancamentos.map((l) => l.id), contains('l4'));
      expect(s.saldoCaixa, 550); // 500 before + 50 from the new entrada
    });

    test('a write failure is surfaced on falhas, not on state', () async {
      final financeiroRepo = _FakeFinanceiroRepository(
        _ledgerComTransferencia(),
      );
      final vm = FinanceiroViewModel(
        financeiroRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );
      await vm.carregar();
      final estadoAntes = vm.state;
      financeiroRepo.falhaAoAdicionar = true;

      final falhas = <GuildFailure>[];
      final sub = vm.falhas.listen(falhas.add);

      await vm.adicionar(_lancamento(id: 'l5'));
      await Future<void>.delayed(Duration.zero);

      expect(falhas, [const GuildFailure(GuildErro.salvar)]);
      expect(vm.state, same(estadoAntes));
      await sub.cancel();
    });
  });

  group('remover', () {
    test('calls the repository and reloads without the entry', () async {
      final financeiroRepo = _FakeFinanceiroRepository(
        _ledgerComTransferencia(),
      );
      final vm = FinanceiroViewModel(
        financeiroRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );
      await vm.carregar();

      await vm.remover('l2'); // the 200 despesa

      expect(financeiroRepo.removido, 'l2');
      final s = vm.state as FinPronto;
      expect(s.lancamentos.map((l) => l.id), isNot(contains('l2')));
      expect(s.saldoCaixa, 700); // 500 before + the 200 despesa restored
    });

    test('a write failure is surfaced on falhas, not on state', () async {
      final financeiroRepo = _FakeFinanceiroRepository(
        _ledgerComTransferencia(),
      );
      final vm = FinanceiroViewModel(
        financeiroRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );
      await vm.carregar();
      final estadoAntes = vm.state;
      financeiroRepo.falhaAoRemover = true;

      final falhas = <GuildFailure>[];
      final sub = vm.falhas.listen(falhas.add);

      await vm.remover('l1');
      await Future<void>.delayed(Duration.zero);

      expect(falhas, [const GuildFailure(GuildErro.salvar)]);
      expect(vm.state, same(estadoAntes));
      await sub.cancel();
    });
  });
}
