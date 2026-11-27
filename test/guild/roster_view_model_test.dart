import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
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

/// Tracks every call `corrigirUltima` receives, and holds the single ficha
/// a hand correction is supposed to land on — a stand-in for the Supabase
/// round trip, so the test below never touches the network.
class _FakeFichasRepo implements FichasRepository {
  _FakeFichasRepo([Ficha? ficha]) : ultima = ficha;
  Ficha? ultima;
  int chamadas = 0;
  String? ultimoJogadorId;
  Map<String, dynamic>? ultimosCampos;

  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      Success(ultima == null ? [] : [ultima!]);

  @override
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async {
    chamadas++;
    ultimoJogadorId = jogadorId;
    ultimosCampos = camposDados;
    final atual = ultima;
    ultima = Ficha(
      id: atual?.id,
      jogadorId: jogadorId,
      dados: {...(atual?.dados ?? {}), ...camposDados},
      runas: atual?.runas ?? const [],
    );
    return const Success<void>(null);
  }
}

void main() {
  test('carregar emits the roster with the role', () async {
    final vm = RosterViewModel(
      _FakeRepo([Jogador(id: '1', nome: 'A')]),
      _FakeFichasRepo(),
      Papel.admin,
    );
    await vm.carregar();
    expect(vm.state, isA<RosterPronto>());
    expect((vm.state as RosterPronto).jogadores, hasLength(1));
    expect((vm.state as RosterPronto).papel, Papel.admin);
  });

  test('sala_guerras may not add a player — the repo is never called', () async {
    final repo = _FakeRepo([]);
    final vm = RosterViewModel(repo, _FakeFichasRepo(), Papel.salaGuerras);
    final ok = await vm.adicionar(Jogador(id: '', nome: 'X'));
    expect(ok, isFalse);
    expect(repo.criados, 0);
  });

  test('adding with a print uploads it before creating', () async {
    final repo = _FakeRepo([]);
    final vm = RosterViewModel(repo, _FakeFichasRepo(), Papel.admin);
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
    final vm = RosterViewModel(repo, _FakeFichasRepo(), Papel.admin);
    final ok = await vm.adicionar(
      Jogador(id: '', nome: 'A'),
      print: Uint8List(512 * 1024 + 1),
      nomeArquivo: 'big.png',
    );
    expect(ok, isFalse);
    expect(repo.subidos, 0);
    expect(repo.criados, 0);
  });

  // I1 — a hand correction used to PATCH `jogadores` only, leaving the
  // detail screen's stat groups (which read the newest `fichas` row)
  // disagreeing with the staff's own fix. `editar` now merges the same
  // changed attribute fields into the latest ficha too.
  test(
    'editar hand-corrects the latest ficha, not only the jogadores row',
    () async {
      final repo = _FakeRepo([Jogador(id: '1', nome: 'A', hp: 5500)]);
      final fichas = _FakeFichasRepo(
        Ficha(id: 'f1', jogadorId: '1', dados: {'hp': 5500}, runas: const []),
      );
      final vm = RosterViewModel(repo, fichas, Papel.admin);

      final ok = await vm.editar('1', {'hp': 55000});

      expect(ok, isTrue);
      expect(fichas.chamadas, 1);
      expect(fichas.ultimoJogadorId, '1');
      expect(fichas.ultima!.dados['hp'], 55000);
    },
  );

  test('editar never sends the audit stamp into the ficha', () async {
    final repo = _FakeRepo([Jogador(id: '1', nome: 'A')]);
    final fichas = _FakeFichasRepo();
    final vm = RosterViewModel(repo, fichas, Papel.admin);

    final ok = await vm.editar('1', {
      'nivel_ataque': 70,
      'atualizado_por': 'uid-1',
      'atualizado_em': '2026-11-27T00:00:00.000Z',
    });

    expect(ok, isTrue);
    expect(fichas.chamadas, 1);
    expect(fichas.ultimosCampos, {'nivel_ataque': 70});
  });

  test(
    'editar inserts a new ficha when a pendente player has none yet',
    () async {
      final repo = _FakeRepo([Jogador(id: '1', nome: 'A')]);
      final fichas = _FakeFichasRepo(); // no history
      final vm = RosterViewModel(repo, fichas, Papel.admin);

      final ok = await vm.editar('1', {'classe': 'Bardo'});

      expect(ok, isTrue);
      expect(fichas.chamadas, 1);
      expect(fichas.ultima!.dados['classe'], 'Bardo');
    },
  );

  test(
    'editar with only audit-stamp-free-empty changes never calls corrigirUltima',
    () async {
      final repo = _FakeRepo([Jogador(id: '1', nome: 'A')]);
      final fichas = _FakeFichasRepo();
      final vm = RosterViewModel(repo, fichas, Papel.admin);

      // Only audit keys changed (e.g. a no-op save) — nothing attribute-wise
      // to merge into a ficha.
      final ok = await vm.editar('1', {
        'atualizado_por': 'uid-1',
        'atualizado_em': '2026-11-27T00:00:00.000Z',
      });

      expect(ok, isTrue);
      expect(fichas.chamadas, 0);
    },
  );
}
