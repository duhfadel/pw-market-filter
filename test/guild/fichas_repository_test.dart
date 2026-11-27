import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';

/// Proves the interface shape compiles and is usable — the real test of a
/// consumer reading it lives on the detail view model (Task 8).
class _FakeFichasRepository implements FichasRepository {
  _FakeFichasRepository(this._historico);
  final List<Ficha> _historico;

  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      Success(_historico);
}

void main() {
  test('historico returns a Success with the fichas', () async {
    final repo = _FakeFichasRepository([
      Ficha(jogadorId: 'j1', dados: {'nivel_ataque': 428}, runas: const []),
    ]);

    final result = await repo.historico('j1');

    expect(result, isA<Success<List<Ficha>>>());
    expect((result as Success<List<Ficha>>).value, hasLength(1));
  });
}
