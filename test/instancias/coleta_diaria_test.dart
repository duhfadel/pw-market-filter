import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _hoje = '2026-11-12';
const _ontem = '2026-11-11';

PersonagemDeInstancia _p(String nome, {int chave = 0, String? em}) =>
    PersonagemDeInstancia(
      nome: nome,
      classe: 'Bardo',
      contagens: {EntradaDeInstancia.chave: chave},
      coletadoEm: em,
    );

void main() {
  test('pegar a diária soma 1 em cada entrada e não toca na chave', () {
    final depois = _p('duhit', chave: 14).comColetaDiaria(_hoje);

    expect(depois.de(EntradaDeInstancia.artefato), 1);
    expect(depois.de(EntradaDeInstancia.arma), 1);
    expect(depois.de(EntradaDeInstancia.armadura), 1);
    expect(depois.de(EntradaDeInstancia.chave), 14, reason: 'a chave não muda');
    expect(depois.pegouEm(_hoje), isTrue);
  });

  test('pegar soma por cima do que já tinha', () {
    final tinha = PersonagemDeInstancia(
      nome: 'x',
      classe: 'Mago',
      contagens: const {
        EntradaDeInstancia.artefato: 3,
        EntradaDeInstancia.armadura: 10,
      },
    );
    final depois = tinha.comColetaDiaria(_hoje);
    expect(depois.de(EntradaDeInstancia.artefato), 4);
    expect(depois.de(EntradaDeInstancia.arma), 1);
    expect(depois.de(EntradaDeInstancia.armadura), 11);
  });

  test('pegar duas vezes no mesmo dia não vale seis entradas', () {
    // É o que impede dois cliques — e é o que deixa o botão do grupo passar
    // por quem já pegou sem o penalizar.
    final uma = _p('x').comColetaDiaria(_hoje);
    final duas = uma.comColetaDiaria(_hoje);
    expect(
      duas.de(EntradaDeInstancia.artefato),
      1,
      reason: 'idempotente no dia',
    );
    expect(
      identical(uma, duas) || duas.de(EntradaDeInstancia.artefato) == 1,
      isTrue,
    );
  });

  test('quem pegou ontem pode pegar hoje', () {
    final p = _p('x', em: _ontem);
    expect(p.pegouEm(_hoje), isFalse);
    final depois = p.comColetaDiaria(_hoje);
    expect(depois.de(EntradaDeInstancia.artefato), 1);
    expect(depois.coletadoEm, _hoje);
  });

  test('o grupo pega por todos os que ainda não pegaram', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'A',
          personagens: [
            _p('cedo', em: _hoje), // já pegou
            _p('tarde'), // não pegou
          ],
        ),
      ],
    );

    expect(plano.grupos[0].faltamHoje(_hoje), 1);
    expect(plano.grupos[0].todosPegaramHoje(_hoje), isFalse);

    final depois = plano.coletaDiariaDoGrupo(0, _hoje);
    // 'cedo' não ganha nada (já tinha pegado), 'tarde' ganha as três.
    expect(depois.grupos[0].personagens[0].de(EntradaDeInstancia.artefato), 0);
    expect(depois.grupos[0].personagens[1].de(EntradaDeInstancia.artefato), 1);
    expect(depois.grupos[0].todosPegaramHoje(_hoje), isTrue);
    expect(depois.grupos[0].faltamHoje(_hoje), 0);
  });

  test('um grupo vazio não diz que todos pegaram', () {
    const g = GrupoDeInstancias(nome: 'vazio');
    expect(g.todosPegaramHoje(_hoje), isFalse);
    expect(g.faltamHoje(_hoje), 0);
  });

  test('a coleta de um personagem mexe só nele', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(nome: 'A', personagens: [_p('a'), _p('b')]),
      ],
    );
    final depois = plano.coletaDiaria(const Morada(0, 0), _hoje);
    expect(depois.grupos[0].personagens[0].de(EntradaDeInstancia.artefato), 1);
    expect(depois.grupos[0].personagens[1].de(EntradaDeInstancia.artefato), 0);
  });

  test('a data sobrevive a renomear e a mexer nas contagens', () {
    final p = _p('x', em: _hoje);
    expect(p.renomeado('y').coletadoEm, _hoje);
    expect(p.com(EntradaDeInstancia.chave, 9).coletadoEm, _hoje);
  });
}
