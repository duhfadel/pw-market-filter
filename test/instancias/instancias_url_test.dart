import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/instancias_url.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _classes = {'Bardo', 'Mago', 'Arqueiro'};

Map<String, List<String>> _q(String s) =>
    Uri.parse('/instancias?$s').queryParametersAll;

PlanoDeInstancias? _ida(PlanoDeInstancias p) =>
    decodeInstancias(_q(encodeInstancias(p)), classesConhecidas: _classes);

PersonagemDeInstancia _p(String nome, String classe, {int chave = 0}) =>
    PersonagemDeInstancia(
      nome: nome,
      classe: classe,
      contagens: {EntradaDeInstancia.chave: chave},
    );

void main() {
  test('grupos e personagens sobrevivem à viagem inteira', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'Principal',
          personagens: [_p('duhit', 'Bardo', chave: 14)],
        ),
        GrupoDeInstancias(
          nome: 'Mula',
          personagens: [_p('mula1', 'Mago', chave: 2)],
        ),
      ],
    );

    final v = _ida(plano)!;
    expect([for (final g in v.grupos) g.nome], ['Principal', 'Mula']);
    expect(v.grupos[0].personagens.single.nome, 'duhit');
    expect(v.grupos[0].personagens.single.de(EntradaDeInstancia.chave), 14);
    expect(v.grupos[1].personagens.single.nome, 'mula1');
  });

  test('cada personagem volta ao grupo certo pelo índice', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(nome: 'A', personagens: [_p('aa', 'Bardo')]),
        GrupoDeInstancias(
          nome: 'B',
          personagens: [_p('bb', 'Mago'), _p('cc', 'Arqueiro')],
        ),
      ],
    );
    final v = _ida(plano)!;
    expect([for (final q in v.grupos[0].personagens) q.nome], ['aa']);
    expect([for (final q in v.grupos[1].personagens) q.nome], ['bb', 'cc']);
  });

  test('um nome de grupo ou de personagem com til sobrevive', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'gru~po',
          personagens: [_p('~duh~it~', 'Bardo')],
        ),
      ],
    );
    final v = _ida(plano)!;
    expect(v.grupos.single.nome, 'gru~po');
    expect(v.grupos.single.personagens.single.nome, '~duh~it~');
  });

  test('acentos e espaços voltam inteiros e o link é legível', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'Conta do João',
          personagens: [_p('Coração', 'Mago')],
        ),
      ],
    );
    final escrito = encodeInstancias(plano);
    final v = _ida(plano)!;
    expect(v.grupos.single.nome, 'Conta do João');
    expect(v.grupos.single.personagens.single.nome, 'Coração');
    expect(escrito, contains('~'), reason: 'o til nunca é escapado');
  });

  test('um índice de grupo fora da lista cai, não inventa grupo', () {
    final v = decodeInstancias(
      _q('g=A&p=0~Bardo~0~0~0~1~~bom&p=5~Mago~0~0~0~2~~orfao'),
      classesConhecidas: _classes,
    )!;
    expect(v.grupos.length, 1);
    expect([for (final q in v.grupos[0].personagens) q.nome], ['bom']);
  });

  test(
    'sem grupo nenhum, o link não diz nada e o estado é relido do disco',
    () {
      expect(decodeInstancias(const {}, classesConhecidas: _classes), isNull);
      expect(
        encodeInstancias(PlanoDeInstancias.inicial()),
        'g=Meus+personagens',
      );
    },
  );

  test('entrada estragada, classe desconhecida e negativo caem sozinhos', () {
    final v = decodeInstancias(
      _q(
        'g=A'
        '&p=0~Bardo~0~0~0~1~~bom'
        '&p=0~Nigromante~0~0~0~2~~classe'
        '&p=0~Mago~-1~0~0~2~~negativo'
        '&p=0~Bardo~0~0~0',
      ),
      classesConhecidas: _classes,
    )!;
    expect([for (final q in v.grupos[0].personagens) q.nome], ['bom']);
  });

  test('a data da coleta diária sobrevive à viagem, e vazia é null', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'A',
          personagens: [
            const PersonagemDeInstancia(
              nome: 'pegou',
              classe: 'Bardo',
              coletadoEm: '2026-11-12',
            ),
            _p('nunca', 'Mago'),
          ],
        ),
      ],
    );
    final v = _ida(plano)!;
    expect(v.grupos[0].personagens[0].coletadoEm, '2026-11-12');
    expect(v.grupos[0].personagens[1].coletadoEm, isNull);
  });

  test('a ordenação não viaja: o link leva a ordem de origem', () {
    final plano = PlanoDeInstancias(
      grupos: [
        GrupoDeInstancias(
          nome: 'A',
          personagens: [_p('a', 'Bardo', chave: 1), _p('b', 'Mago', chave: 9)],
        ),
      ],
    ).ordenandoPor(EntradaDeInstancia.chave);
    expect(
      [for (final q in _ida(plano)!.grupos[0].personagens) q.nome],
      ['a', 'b'],
    );
  });
}
