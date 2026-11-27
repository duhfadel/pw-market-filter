import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/financeiro_repository.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';

/// Proves the interface shape compiles and is usable — the same guard the
/// other guild repositories' fakes keep.
class _FakeFinanceiroRepository implements FinanceiroRepository {
  _FakeFinanceiroRepository(this._lancamentos);
  final List<Lancamento> _lancamentos;
  Lancamento? adicionado;
  String? removido;

  @override
  Future<Result<List<Lancamento>>> lista() async => Success(_lancamentos);

  @override
  Future<Result<void>> adicionar(Lancamento l) async {
    adicionado = l;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> remover(String id) async {
    removido = id;
    return const Success<void>(null);
  }
}

Lancamento _lancamento({String id = 'l1'}) => Lancamento(
  id: id,
  tipo: TipoLancamento.entrada,
  pote: Pote.caixa,
  valor: 1000,
  categoria: CategoriaEntrada.guildAtiva,
  data: DateTime(2026, 11, 27),
);

void main() {
  test('lista returns a Success with the ledger', () async {
    final repo = _FakeFinanceiroRepository([_lancamento()]);

    final result = await repo.lista();

    expect(result, isA<Success<List<Lancamento>>>());
    expect((result as Success<List<Lancamento>>).value, hasLength(1));
  });

  test('adicionar returns Success and the fake sees what was passed', () async {
    final repo = _FakeFinanceiroRepository(const []);
    final lancamento = _lancamento();

    final result = await repo.adicionar(lancamento);

    expect(result, isA<Success<void>>());
    expect(repo.adicionado, same(lancamento));
  });

  test('remover returns Success and the fake sees the id', () async {
    final repo = _FakeFinanceiroRepository(const []);

    final result = await repo.remover('l1');

    expect(result, isA<Success<void>>());
    expect(repo.removido, 'l1');
  });

  test('Lancamento round-trips through toJson/fromJson', () {
    final original = _lancamento();

    final restored = Lancamento.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.tipo, original.tipo);
    expect(restored.pote, original.pote);
    expect(restored.valor, original.valor);
    expect(restored.categoria, original.categoria);
    expect(restored.data, original.data);
  });
}
