import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/memoria/browser_memory.dart';
import 'package:pw_market_filter/features/instancias/data/instancias_memoria.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _classes = {'Bardo', 'Mago'};

class _Gaveta implements BrowserMemory {
  _Gaveta([this.valor]);
  String? valor;
  bool estoura = false;
  @override
  String? read() => estoura ? null : valor;
  @override
  void write(String v) => valor = v;
}

PersonagemDeInstancia _p(String nome, String classe, {int chave = 0}) =>
    PersonagemDeInstancia(
      nome: nome,
      classe: classe,
      contagens: {EntradaDeInstancia.chave: chave},
    );

void main() {
  test('grupos e personagens sobrevivem a gravar e ler', () {
    final g = _Gaveta();
    InstanciasMemoria(g).gravar(
      PlanoDeInstancias(
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
      ),
    );

    final lido = InstanciasMemoria(g).ler(classesConhecidas: _classes);
    expect([for (final x in lido.grupos) x.nome], ['Principal', 'Mula']);
    expect(lido.grupos[0].personagens.single.de(EntradaDeInstancia.chave), 14);
  });

  test('as contagens são gravadas pelo nome do enum, nunca pelo índice', () {
    final g = _Gaveta();
    InstanciasMemoria(g).gravar(
      PlanoDeInstancias(
        grupos: [
          GrupoDeInstancias(
            nome: 'A',
            personagens: [_p('x', 'Mago', chave: 7)],
          ),
        ],
      ),
    );
    expect(g.valor, contains('"chave":7'));
  });

  test('ficheiro estragado é uma lista inicial e nunca um erro', () {
    expect(
      InstanciasMemoria(
        _Gaveta('nao e json'),
      ).ler(classesConhecidas: _classes).vazio,
      isTrue,
    );
    expect(
      InstanciasMemoria(
        _Gaveta('{"nao":"e lista"}'),
      ).ler(classesConhecidas: _classes).grupos.length,
      1,
    );
  });

  test('uma gaveta que não abre começa com a lista inicial, com um grupo', () {
    final g = _Gaveta('[]')..estoura = true;
    final p = InstanciasMemoria(g).ler(classesConhecidas: _classes);
    expect(p.vazio, isTrue);
    expect(p.grupos.length, 1, reason: 'sempre há onde pôr o primeiro');
  });

  test('personagens sem nome ou de classe desconhecida caem, o grupo fica', () {
    final g = _Gaveta(
      '[{"nome":"G","personagens":['
      '{"nome":"","classe":"Mago"},'
      '{"nome":"y","classe":"Nigromante"},'
      '{"nome":"bom","classe":"Mago","chave":2}]}]',
    );
    final lido = InstanciasMemoria(g).ler(classesConhecidas: _classes);
    expect([for (final x in lido.grupos[0].personagens) x.nome], ['bom']);
  });

  test('o link aponta para a ferramenta e leva os grupos', () {
    final link = InstanciasMemoria(_Gaveta()).link(
      PlanoDeInstancias(
        grupos: [
          GrupoDeInstancias(
            nome: 'Principal',
            personagens: [_p('duhit', 'Bardo')],
          ),
        ],
      ),
    );
    expect(link, startsWith('https://portalpw.net/#/instancias?'));
    expect(link, contains('duhit'));
    expect(link, contains('Principal'));
  });
}
