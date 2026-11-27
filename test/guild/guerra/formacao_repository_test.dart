import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/formacao_repository.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/grupo_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/membro_guerra.dart';

/// Proves the interface shape compiles and is usable — the real test of a
/// consumer reading and writing it lives on the board's view model.
class _FakeFormacaoRepository implements FormacaoRepository {
  _FakeFormacaoRepository(this._formacao);
  final FormacaoGuerra _formacao;
  FormacaoGuerra? salva;

  @override
  Future<Result<FormacaoGuerra>> carregar() async => Success(_formacao);

  @override
  Future<Result<void>> salvar(FormacaoGuerra f) async {
    salva = f;
    return const Success<void>(null);
  }
}

void main() {
  test('carregar returns a Success with the formation', () async {
    final repo = _FakeFormacaoRepository(
      FormacaoGuerra(
        grupos: [
          GrupoGuerra(
            nome: 'Grupo 1',
            cor: '#FF0000',
            membros: [MembroGuerra(jogadorId: 'j1')],
          ),
        ],
      ),
    );

    final result = await repo.carregar();

    expect(result, isA<Success<FormacaoGuerra>>());
    expect((result as Success<FormacaoGuerra>).value.grupos, hasLength(1));
  });

  test('salvar returns Success and the fake sees what was passed', () async {
    final repo = _FakeFormacaoRepository(FormacaoGuerra(grupos: const []));
    final formacao = FormacaoGuerra(
      grupos: [GrupoGuerra(nome: 'Grupo 1', cor: '#FF0000')],
    );

    final result = await repo.salvar(formacao);

    expect(result, isA<Success<void>>());
    expect(repo.salva, same(formacao));
  });

  test('FormacaoGuerra round-trips through the pts column shape', () {
    final original = FormacaoGuerra(
      grupos: [
        GrupoGuerra(
          nome: 'Grupo 1',
          cor: '#FF0000',
          membros: [MembroGuerra(jogadorId: 'j1', lider: true)],
        ),
      ],
    );

    // `salvar` writes `toJson()['grupos']` under the `pts` column;
    // `carregar` reads it back as `FormacaoGuerra.fromJson({'grupos': pts})`.
    final pts = original.toJson()['grupos'];
    final restored = FormacaoGuerra.fromJson({'grupos': pts});

    expect(restored.grupos, hasLength(1));
    expect(restored.grupos.first.nome, 'Grupo 1');
    expect(restored.grupos.first.membros.single.jogadorId, 'j1');
    expect(restored.grupos.first.membros.single.lider, isTrue);
  });
}
