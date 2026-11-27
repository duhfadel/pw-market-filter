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
  int subidos = 0;
  @override
  Future<Result<List<Jogador>>> lista() async => Success(_lista);
  @override
  Future<Result<void>> criar(Jogador j) async {
    criados++;
    return const Success<void>(null);
  }

  @override
  Future<Result<String>> subirPrint(Uint8List b, String n) async {
    subidos++;
    return Success(n);
  }

  @override
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async =>
      const Success<void>(null);
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

  test('adding with a print uploads it before creating', () async {
    final repo = _FakeRepo([]);
    final vm = RosterViewModel(repo, Papel.admin);
    final ok = await vm.adicionar(
      Jogador(id: '', nome: 'A'),
      print: Uint8List(10),
      nomeArquivo: 'a.png',
    );
    expect(ok, isTrue);
    expect(repo.subidos, 1);
    expect(repo.criados, 1);
  });

  test('a print over 512 KB is refused before any upload', () async {
    final repo = _FakeRepo([]);
    final vm = RosterViewModel(repo, Papel.admin);
    final ok = await vm.adicionar(
      Jogador(id: '', nome: 'A'),
      print: Uint8List(512 * 1024 + 1),
      nomeArquivo: 'big.png',
    );
    expect(ok, isFalse);
    expect(repo.subidos, 0);
    expect(repo.criados, 0);
  });
}
