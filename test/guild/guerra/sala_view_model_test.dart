import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/formacao_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/grupo_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/membro_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/sala_estado.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/sala_view_model.dart';

class _FakeFormacaoRepository implements FormacaoRepository {
  _FakeFormacaoRepository(
    this._formacao, {
    this.falhaAoSalvar = false,
    this.salvoEm,
    this.salvoPorEmail,
  });
  final FormacaoGuerra _formacao;
  final bool falhaAoSalvar;
  final DateTime? salvoEm;
  final String? salvoPorEmail;
  bool falhaAoCarregar = false;
  FormacaoGuerra? salva;

  @override
  Future<Result<FormacaoCarregada>> carregar() async {
    if (falhaAoCarregar) {
      return const Failure(GuildFailure(GuildErro.carregar));
    }
    return Success(
      FormacaoCarregada(
        _formacao,
        salvoEm: salvoEm,
        salvoPorEmail: salvoPorEmail,
      ),
    );
  }

  @override
  Future<Result<String?>> salvar(FormacaoGuerra f) async {
    if (falhaAoSalvar) return const Failure(GuildFailure(GuildErro.salvar));
    salva = f;
    return const Success('quemsalvou@guilda.com');
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

Jogador _jogador(String id, {String status = 'transcrito'}) =>
    Jogador(id: id, nome: 'Jogador $id', status: status);

FormacaoGuerra _formacaoComUmGrupo({List<MembroGuerra> membros = const []}) =>
    FormacaoGuerra(
      grupos: [GrupoGuerra(nome: 'Pt 1', cor: '#56A8F5', membros: membros)],
    );

void main() {
  group('carregar', () {
    test(
      'emits SalaPronta with only the transcribed players in the roster',
      () async {
        final jogadores = [
          _jogador('a'),
          _jogador('b'),
          _jogador('c'),
          _jogador('d', status: 'pendente'),
        ];
        final vm = SalaGuerrasViewModel(
          _FakeFormacaoRepository(_formacaoComUmGrupo()),
          _FakeJogadoresRepository(jogadores),
        );

        await vm.carregar();

        final s = vm.state;
        expect(s, isA<SalaPronta>());
        expect(
          (s as SalaPronta).jogadores.map((j) => j.id),
          unorderedEquals(['a', 'b', 'c']),
        );
      },
    );

    test('prunes formation members outside the transcribed roster', () async {
      final formacao = _formacaoComUmGrupo(
        membros: [
          MembroGuerra(jogadorId: 'a'),
          MembroGuerra(jogadorId: 'sumiu'),
        ],
      );
      final vm = SalaGuerrasViewModel(
        _FakeFormacaoRepository(formacao),
        _FakeJogadoresRepository([_jogador('a'), _jogador('b')]),
      );

      await vm.carregar();

      final s = vm.state as SalaPronta;
      expect(s.formacao.grupos.single.membros.map((m) => m.jogadorId), ['a']);
    });

    test('seeds salvoEm and salvoPorEmail from what the repository loaded, '
        'not only from a local save', () async {
      final quando = DateTime(2026, 11, 20, 18, 30);
      final vm = SalaGuerrasViewModel(
        _FakeFormacaoRepository(
          _formacaoComUmGrupo(),
          salvoEm: quando,
          salvoPorEmail: 'colega@guilda.com',
        ),
        _FakeJogadoresRepository([_jogador('a')]),
      );

      await vm.carregar();

      final s = vm.state as SalaPronta;
      expect(s.salvoEm, quando);
      expect(s.salvoPorEmail, 'colega@guilda.com');
    });

    test('a failure loading either side emits SalaFalha', () async {
      final formacaoRepo = _FakeFormacaoRepository(_formacaoComUmGrupo())
        ..falhaAoCarregar = true;
      final vm = SalaGuerrasViewModel(
        formacaoRepo,
        _FakeJogadoresRepository([_jogador('a')]),
      );

      await vm.carregar();

      expect(vm.state, isA<SalaFalha>());
    });
  });

  group('mover', () {
    test(
      'places the player in the destination group and out of disponiveis',
      () async {
        final vm = SalaGuerrasViewModel(
          _FakeFormacaoRepository(_formacaoComUmGrupo()),
          _FakeJogadoresRepository([_jogador('a'), _jogador('b')]),
        );
        await vm.carregar();
        expect(
          (vm.state as SalaPronta).disponiveis,
          unorderedEquals(['a', 'b']),
        );

        vm.mover('a', 0);

        final s = vm.state as SalaPronta;
        expect(s.formacao.grupos[0].membros.single.jogadorId, 'a');
        expect(s.disponiveis, ['b']);
      },
    );

    test('destino null removes the player back into disponiveis', () async {
      final formacao = _formacaoComUmGrupo(
        membros: [MembroGuerra(jogadorId: 'a')],
      );
      final vm = SalaGuerrasViewModel(
        _FakeFormacaoRepository(formacao),
        _FakeJogadoresRepository([_jogador('a')]),
      );
      await vm.carregar();

      vm.mover('a', null);

      final s = vm.state as SalaPronta;
      expect(s.formacao.grupos[0].membros, isEmpty);
      expect(s.disponiveis, ['a']);
    });
  });

  test('alternarLider toggles leadership on the right group', () async {
    final formacao = _formacaoComUmGrupo(
      membros: [MembroGuerra(jogadorId: 'a')],
    );
    final vm = SalaGuerrasViewModel(
      _FakeFormacaoRepository(formacao),
      _FakeJogadoresRepository([_jogador('a')]),
    );
    await vm.carregar();

    vm.alternarLider(0, 'a');

    expect(
      (vm.state as SalaPronta).formacao.grupos[0].membros.single.lider,
      isTrue,
    );
  });

  test('renomear and recolorir rebuild only the targeted group', () async {
    final vm = SalaGuerrasViewModel(
      _FakeFormacaoRepository(_formacaoComUmGrupo()),
      _FakeJogadoresRepository(const []),
    );
    await vm.carregar();

    vm.renomear(0, 'Linha de frente');
    vm.recolorir(0, '#FF0000');

    final grupo = (vm.state as SalaPronta).formacao.grupos.single;
    expect(grupo.nome, 'Linha de frente');
    expect(grupo.cor, '#FF0000');
  });

  test('novaPt appends an empty group and removerPt drops it', () async {
    final vm = SalaGuerrasViewModel(
      _FakeFormacaoRepository(_formacaoComUmGrupo()),
      _FakeJogadoresRepository(const []),
    );
    await vm.carregar();

    vm.novaPt();
    expect((vm.state as SalaPronta).formacao.grupos, hasLength(2));

    vm.removerPt(0);
    expect((vm.state as SalaPronta).formacao.grupos, hasLength(1));
  });

  group('salvar', () {
    test(
      'on success re-emits SalaPronta with salvoEm and salvoPorEmail set',
      () async {
        final repo = _FakeFormacaoRepository(_formacaoComUmGrupo());
        final vm = SalaGuerrasViewModel(
          repo,
          _FakeJogadoresRepository(const []),
        );
        await vm.carregar();
        expect((vm.state as SalaPronta).salvoEm, isNull);

        await vm.salvar();

        final s = vm.state as SalaPronta;
        expect(s.salvoEm, isNotNull);
        expect(s.salvoPorEmail, 'quemsalvou@guilda.com');
        expect(repo.salva, isNotNull);
      },
    );

    test(
      'on failure the error is surfaced on falhasSalvar, never swallowed',
      () async {
        final vm = SalaGuerrasViewModel(
          _FakeFormacaoRepository(_formacaoComUmGrupo(), falhaAoSalvar: true),
          _FakeJogadoresRepository(const []),
        );
        await vm.carregar();

        final falhas = <GuildFailure>[];
        final sub = vm.falhasSalvar.listen(falhas.add);

        await vm.salvar();
        // let the broadcast stream's listener fire.
        await Future<void>.delayed(Duration.zero);

        expect(falhas, hasLength(1));
        expect(falhas.single.erro, GuildErro.salvar);
        // state is untouched by the failed save — still correct, just unsaved.
        expect((vm.state as SalaPronta).salvoEm, isNull);

        await sub.cancel();
      },
    );
  });
}
