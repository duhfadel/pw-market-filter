import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/instancias_url.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _classes = {'Bardo', 'Mago', 'Arqueiro'};

Map<String, List<String>> _query(String s) =>
    Uri.parse('/instancias?$s').queryParametersAll;

PlanoDeInstancias _ida(PlanoDeInstancias p) =>
    decodeInstancias(_query(encodeInstancias(p)), classesConhecidas: _classes);

void main() {
  test('a lista sobrevive à viagem inteira', () {
    final plano = PlanoDeInstancias(
      personagens: [
        PersonagemDeInstancia(
          nome: 'duhit',
          classe: 'Bardo',
          contagens: const {
            EntradaDeInstancia.artefato: 3,
            EntradaDeInstancia.arma: 1,
            EntradaDeInstancia.armadura: 2,
            EntradaDeInstancia.chave: 14,
          },
        ),
        const PersonagemDeInstancia(nome: 'Mulexta', classe: 'Mago'),
      ],
    );

    final volta = _ida(plano);

    expect(volta.personagens.length, 2);
    expect(volta.personagens.first.nome, 'duhit');
    expect(volta.personagens.first.classe, 'Bardo');
    expect(volta.personagens.first.de(EntradaDeInstancia.chave), 14);
    expect(volta.personagens.last.nome, 'Mulexta');
    expect(volta.personagens.last.de(EntradaDeInstancia.chave), 0);
  });

  test('um apelido com til sobrevive, porque o nome vai no fim', () {
    // **É este o caso que escolhe o formato.** Tudo antes do nome tem aridade
    // fixa, portanto o que sobra depois da quinta separação é o nome, com tis
    // lá dentro. Um formato que o pusesse no meio partia-se aqui.
    const estranho = PersonagemDeInstancia(nome: '~duh~it~', classe: 'Bardo');

    expect(
      _ida(
        const PlanoDeInstancias(personagens: [estranho]),
      ).personagens.single.nome,
      '~duh~it~',
    );
  });

  test('acentos e espaços voltam inteiros e o link é legível', () {
    const quem = PersonagemDeInstancia(
      nome: 'Coração da Névoa',
      classe: 'Mago',
    );
    final escrito = encodeInstancias(
      const PlanoDeInstancias(personagens: [quem]),
    );

    expect(
      _ida(
        const PlanoDeInstancias(personagens: [quem]),
      ).personagens.single.nome,
      'Coração da Névoa',
    );
    // O til nunca é escapado — é o que mantém o link legível para quem decide
    // se clica. Ver a nota em `instancias_url.dart`.
    expect(escrito, contains('~'));
  });

  test('a ordenação não viaja: o link leva a ordem que o dono escreveu', () {
    final plano = PlanoDeInstancias(
      personagens: [
        PersonagemDeInstancia(
          nome: 'a',
          classe: 'Bardo',
          contagens: const {EntradaDeInstancia.chave: 1},
        ),
        PersonagemDeInstancia(
          nome: 'b',
          classe: 'Mago',
          contagens: const {EntradaDeInstancia.chave: 9},
        ),
      ],
    ).ordenandoPor(EntradaDeInstancia.chave);

    expect([for (final p in _ida(plano).personagens) p.nome], ['a', 'b']);
  });

  test('uma entrada estragada cai sozinha e não leva as outras', () {
    // Um link cortado a meio por um cliente de chat é o caso normal disto.
    final lido = decodeInstancias(
      _query('p=Bardo~1~0~0~2~bom&p=Bardo~x~0~0~2~letra&p=Bardo~1~0~0'),
      classesConhecidas: _classes,
    );

    expect([for (final p in lido.personagens) p.nome], ['bom']);
  });

  test('classe desconhecida e número negativo são recusados', () {
    final lido = decodeInstancias(
      _query('p=Nigromante~1~0~0~2~classe&p=Mago~-1~0~0~2~negativo'),
      classesConhecidas: _classes,
    );

    expect(lido.personagens, isEmpty);
  });

  test('nome vazio não entra', () {
    // Uma linha sem nome é uma linha que ninguém consegue identificar na
    // própria tabela.
    final lido = decodeInstancias(
      _query('p=Mago~1~0~0~2~   '),
      classesConhecidas: _classes,
    );

    expect(lido.personagens, isEmpty);
  });

  test('o tecto existe para o endereço continuar a ser um link', () {
    final muitos = PlanoDeInstancias(
      personagens: [
        for (var i = 0; i < maximoDePersonagens + 20; i++)
          PersonagemDeInstancia(nome: 'p$i', classe: 'Mago'),
      ],
    );

    expect(_ida(muitos).personagens.length, maximoDePersonagens);
  });

  test('um plano vazio escreve um link sem pergunta nenhuma', () {
    expect(encodeInstancias(const PlanoDeInstancias()), isEmpty);
  });
}
