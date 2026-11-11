import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

PersonagemDeInstancia _p(
  String nome,
  String classe, {
  int chave = 0,
  int arma = 0,
}) => PersonagemDeInstancia(
  nome: nome,
  classe: classe,
  contagens: {EntradaDeInstancia.chave: chave, EntradaDeInstancia.arma: arma},
);

PlanoDeInstancias _plano() => PlanoDeInstancias(
  grupos: [
    GrupoDeInstancias(
      nome: 'Principal',
      personagens: [
        _p('duhit', 'Bardo', chave: 14),
        _p('farmante', 'Arqueiro', chave: 31),
      ],
    ),
    GrupoDeInstancias(
      nome: 'Mula',
      personagens: [_p('mula1', 'Mago', chave: 2)],
    ),
  ],
);

List<String> _nomes(PlanoDeInstancias p, int g) => [
  for (final q in p.emOrdem(g)) q.nome,
];

void main() {
  test('o subtotal é por grupo e o total soma todos', () {
    final p = _plano();
    expect(p.grupos[0].total(EntradaDeInstancia.chave), 45);
    expect(p.grupos[1].total(EntradaDeInstancia.chave), 2);
    expect(p.total(EntradaDeInstancia.chave), 47);
    expect(p.quantosPersonagens, 3);
  });

  test('uma lista nova nasce com um grupo, nunca sem grupo nenhum', () {
    final p = PlanoDeInstancias.inicial();
    expect(p.grupos.length, 1);
    expect(p.vazio, isTrue);
    expect(p.grupos.single.nome, PlanoDeInstancias.nomeInicial);
  });

  test('vazio é nenhum personagem, e não nenhum grupo', () {
    final so = PlanoDeInstancias(
      grupos: [
        const GrupoDeInstancias(nome: 'a'),
        const GrupoDeInstancias(nome: 'b'),
      ],
    );
    expect(so.vazio, isTrue, reason: 'dois grupos vazios ainda é vazio');
  });

  test('ordenar ordena dentro de cada grupo e não mistura', () {
    final o = _plano().ordenandoPor(EntradaDeInstancia.chave);
    expect(_nomes(o, 0), ['farmante', 'duhit'], reason: '31 antes de 14');
    expect(_nomes(o, 1), ['mula1']);
  });

  test('ordenar é uma vista: a lista gravada não muda', () {
    final o = _plano().ordenandoPor(EntradaDeInstancia.chave);
    expect(
      [for (final q in o.grupos[0].personagens) q.nome],
      ['duhit', 'farmante'],
    );
  });

  test('arrastar move um personagem de um grupo para outro', () {
    // O coração do pedido: a pessoa arrasta a mula do grupo Principal para o
    // grupo Mula.
    final movido = _plano().movendoPersonagem(const Morada(0, 1), 1, 1);
    expect(_nomes(movido, 0), ['duhit'], reason: 'farmante saiu');
    expect(_nomes(movido, 1), [
      'mula1',
      'farmante',
    ], reason: 'e chegou ao fim da Mula');
    // O total geral não muda: moveu-se, não se criou nem apagou.
    expect(movido.total(EntradaDeInstancia.chave), 47);
  });

  test('arrastar dentro do mesmo grupo reordena sem errar por um', () {
    // Mover o primeiro para depois do segundo: sem o ajuste, o índice de
    // chegada apontaria para a lista antiga e erraria uma casa.
    final r = _plano().movendoPersonagem(const Morada(0, 0), 0, 2);
    expect(_nomes(r, 0), ['farmante', 'duhit']);
  });

  test(
    'tirar um grupo leva os personagens dele, com desfazer que repõe o lugar',
    () {
      final p = _plano();
      final sem = p.semOGrupo(0);
      expect(sem.grupos.length, 1);
      expect(sem.grupos.single.nome, 'Mula');

      final volta = sem.inserindoGrupo(0, p.grupos[0]);
      expect([for (final g in volta.grupos) g.nome], ['Principal', 'Mula']);
    },
  );

  test('tirar o último grupo deixa um inicial, nunca zero grupos', () {
    final so = PlanoDeInstancias(
      grupos: [const GrupoDeInstancias(nome: 'único')],
    );
    final sem = so.semOGrupo(0);
    expect(sem.grupos.length, 1);
    expect(sem.grupos.single.nome, PlanoDeInstancias.nomeInicial);
  });

  test('tirar e repor um personagem acerta o grupo e o lugar', () {
    final p = _plano();
    final sem = p.semOPersonagem(const Morada(0, 0));
    expect(_nomes(sem, 0), ['farmante']);
    final volta = sem.inserindoPersonagem(
      const Morada(0, 0),
      p.grupos[0].personagens[0],
    );
    expect(_nomes(volta, 0), ['duhit', 'farmante']);
  });

  test('contar e renomear mexem no personagem certo do grupo certo', () {
    final p = _plano();
    final c = p.contando(const Morada(1, 0), EntradaDeInstancia.chave, 9);
    expect(c.grupos[1].personagens[0].de(EntradaDeInstancia.chave), 9);
    expect(
      c.grupos[0].personagens[0].de(EntradaDeInstancia.chave),
      14,
      reason: 'o outro grupo não mexeu',
    );

    final r = p.renomeandoGrupo(1, 'Mulas de TW');
    expect(r.grupos[1].nome, 'Mulas de TW');
  });
}
