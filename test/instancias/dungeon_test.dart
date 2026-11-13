import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

PersonagemDeInstancia _p(String nome, {int artefato = 0, int chave = 0}) =>
    PersonagemDeInstancia(
      nome: nome,
      classe: 'Bardo',
      contagens: {
        EntradaDeInstancia.artefato: artefato,
        EntradaDeInstancia.chave: chave,
      },
    );

void main() {
  test('finalizar uma dungeon gasta 1 da entrada e dá +6 chaves', () {
    final depois = _p(
      'x',
      artefato: 3,
      chave: 10,
    ).comDungeon(EntradaDeInstancia.artefato);
    expect(depois.de(EntradaDeInstancia.artefato), 2);
    expect(depois.de(EntradaDeInstancia.chave), 16);
  });

  test('quem está a zero daquela entrada não faz a dungeon', () {
    final igual = _p(
      'x',
      artefato: 0,
      chave: 10,
    ).comDungeon(EntradaDeInstancia.artefato);
    expect(igual.de(EntradaDeInstancia.artefato), 0);
    expect(
      igual.de(EntradaDeInstancia.chave),
      10,
      reason: 'sem entrada, sem chave',
    );
  });

  test('o grupo finaliza por todos que têm a entrada, e conta certo', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'A',
          personagens: [
            _p('tem', artefato: 2, chave: 0),
            _p('tambem', artefato: 1, chave: 5),
            _p('nao', artefato: 0, chave: 100),
          ],
        ),
      ],
    );

    expect(plano.grupos[0].podemDungeon(EntradaDeInstancia.artefato), 2);

    final depois = plano.finalizarDungeonNoGrupo(
      0,
      EntradaDeInstancia.artefato,
    );
    // 'tem': 2->1 artefato, 0->6 chave.
    expect(depois.grupos[0].personagens[0].de(EntradaDeInstancia.artefato), 1);
    expect(depois.grupos[0].personagens[0].de(EntradaDeInstancia.chave), 6);
    // 'tambem': 1->0 artefato, 5->11 chave.
    expect(depois.grupos[0].personagens[1].de(EntradaDeInstancia.artefato), 0);
    expect(depois.grupos[0].personagens[1].de(EntradaDeInstancia.chave), 11);
    // 'nao': intacto.
    expect(depois.grupos[0].personagens[2].de(EntradaDeInstancia.chave), 100);
  });
}
