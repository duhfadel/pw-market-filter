import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/roster_state.dart';
import 'package:pw_market_filter/features/guild/ui/roster_view_model.dart';

class _FakeRepo implements JogadoresRepository {
  _FakeRepo(this._lista);
  final List<Jogador> _lista;
  int criados = 0;
  @override
  Future<Result<List<Jogador>>> lista() async => Success(_lista);
  @override
  Future<Result<void>> criar(Jogador j) async {
    criados++;
    return const Success<void>(null);
  }

  @override
  Future<Result<String>> subirPrint(Uint8List b, String n) async =>
      Success(n);
}

void main() {
  test('carregar emits the roster with the role', () async {
    final vm = RosterViewModel(_FakeRepo([Jogador(id: '1', nome: 'A')]), Papel.admin);
    await vm.carregar();
    expect(vm.state, isA<RosterPronto>());
    expect((vm.state as RosterPronto).jogadores, hasLength(1));
    expect((vm.state as RosterPronto).papel, Papel.admin);
  });

  test('sala_guerras may not add a player — the repo is never called', () async {
    final repo = _FakeRepo([]);
    final vm = RosterViewModel(repo, Papel.salaGuerras);
    final ok = await vm.adicionar(Jogador(id: '', nome: 'X'));
    expect(ok, isFalse);
    expect(repo.criados, 0);
  });
}
