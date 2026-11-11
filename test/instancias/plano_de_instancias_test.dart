import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

PersonagemDeInstancia _p(
  String nome,
  String classe, {
  int artefato = 0,
  int arma = 0,
  int armadura = 0,
  int chave = 0,
}) => PersonagemDeInstancia(
  nome: nome,
  classe: classe,
  contagens: {
    EntradaDeInstancia.artefato: artefato,
    EntradaDeInstancia.arma: arma,
    EntradaDeInstancia.armadura: armadura,
    EntradaDeInstancia.chave: chave,
  },
);

final _plano = PlanoDeInstancias(
  personagens: [
    _p('duhit', 'Bardo', artefato: 3, chave: 14),
    _p('Mulexta', 'Mago', armadura: 1, chave: 2),
    _p('farmante', 'Arqueiro', artefato: 5, arma: 5, chave: 31),
  ],
);

List<String> _nomes(PlanoDeInstancias p) => [for (final q in p.emOrdem) q.nome];

void main() {
  test('a soma de baixo é a única resposta que nenhuma linha dá', () {
    expect(_plano.total(EntradaDeInstancia.chave), 47);
    expect(_plano.total(EntradaDeInstancia.artefato), 8);
    expect(_plano.total(EntradaDeInstancia.arma), 5);
  });

  test('ordenar por uma coluna põe quem tem mais em cima', () {
    // A pergunta que fez a ferramenta existir: quais têm mais e quais têm
    // menos chaves.
    final ordenado = _plano.ordenandoPor(EntradaDeInstancia.chave);

    expect(_nomes(ordenado), ['farmante', 'duhit', 'Mulexta']);
  });

  test('ordenar é uma vista e nunca mexe na lista gravada', () {
    // **É isto que impede uma ordenação de se tornar permanente.** O que é
    // gravado e o que viaja no link é `personagens`, a ordem em que o dono
    // os escreveu; tocar num cabeçalho e recarregar a página não pode
    // deixá-lo com a lista baralhada para sempre.
    final ordenado = _plano.ordenandoPor(EntradaDeInstancia.chave);

    expect(
      [for (final p in ordenado.personagens) p.nome],
      ['duhit', 'Mulexta', 'farmante'],
    );
  });

  test('tocar na mesma coluna outra vez volta à ordem de entrada', () {
    final ida = _plano.ordenandoPor(EntradaDeInstancia.chave);
    final volta = ida.ordenandoPor(EntradaDeInstancia.chave);

    expect(volta.ordem, isA<OrdemDeEntrada>());
    expect(_nomes(volta), ['duhit', 'Mulexta', 'farmante']);
  });

  test('empate não baralha: fica a ordem de entrada', () {
    // Dez personagens com zero chaves não podem saltar de sítio só porque
    // alguém tocou num cabeçalho — a tabela ficaria a parecer aleatória.
    final zeros = PlanoDeInstancias(
      personagens: [_p('a', 'Bardo'), _p('b', 'Mago'), _p('c', 'Arqueiro')],
    ).ordenandoPor(EntradaDeInstancia.chave);

    expect(_nomes(zeros), ['a', 'b', 'c']);
  });

  test('ausente é zero, e negativo não existe', () {
    const vazio = PersonagemDeInstancia(nome: 'x', classe: 'Mago');

    expect(vazio.de(EntradaDeInstancia.chave), 0);
    expect(
      vazio.com(EntradaDeInstancia.chave, -3).de(EntradaDeInstancia.chave),
      0,
    );
  });

  test('tirar e trocar mexem no lugar certo da lista de origem', () {
    expect(_nomes(_plano.semO(1)), ['duhit', 'farmante']);
    expect(_nomes(_plano.trocando(0, _p('outro', 'Bardo'))), [
      'outro',
      'Mulexta',
      'farmante',
    ]);
  });
}
