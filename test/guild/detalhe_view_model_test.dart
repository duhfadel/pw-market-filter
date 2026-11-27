import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/domain/delta.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/detalhe_estado.dart';
import 'package:pw_market_filter/features/guild/ui/detalhe_view_model.dart';

class _FakeFichasRepository implements FichasRepository {
  _FakeFichasRepository(this._historico);
  final List<Ficha> _historico;

  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      Success(_historico);

  @override
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async => const Success<void>(null);
}

class _FalhaFichasRepository implements FichasRepository {
  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      const Failure(GuildFailure(GuildErro.carregar));

  @override
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async => const Failure(GuildFailure(GuildErro.salvar));
}

void main() {
  final jogador = Jogador(id: 'j1', nome: 'Leandrim');

  test(
    'loads history, newest ficha is atual, previous feeds the delta',
    () async {
      final historico = [
        Ficha(jogadorId: 'j1', dados: {'nivel_ataque': 428}, runas: const []),
        Ficha(jogadorId: 'j1', dados: {'nivel_ataque': 396}, runas: const []),
      ];
      final vm = DetalheViewModel(_FakeFichasRepository(historico), jogador);

      await vm.carregar();

      expect(vm.state, isA<DetalhePronto>());
      final pronto = vm.state as DetalhePronto;
      expect(pronto.jogador, jogador);
      expect(pronto.atual.dados['nivel_ataque'], 428);
      expect(pronto.delta['nivel_ataque']!.rumo, Rumo.subiu);
    },
  );

  test('a single ficha yields an empty delta', () async {
    final historico = [
      Ficha(jogadorId: 'j1', dados: {'nivel_ataque': 428}, runas: const []),
    ];
    final vm = DetalheViewModel(_FakeFichasRepository(historico), jogador);

    await vm.carregar();

    final pronto = vm.state as DetalhePronto;
    expect(pronto.delta, isEmpty);
  });

  test('no fichas at all yields DetalheSemFicha', () async {
    final vm = DetalheViewModel(_FakeFichasRepository([]), jogador);

    await vm.carregar();

    expect(vm.state, isA<DetalheSemFicha>());
  });

  test('a repository failure yields DetalheFalha', () async {
    final vm = DetalheViewModel(_FalhaFichasRepository(), jogador);

    await vm.carregar();

    expect(vm.state, isA<DetalheFalha>());
  });
}
