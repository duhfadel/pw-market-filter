import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/memoria/browser_memory.dart';
import 'package:pw_market_filter/features/instancias/data/instancias_memoria.dart';
import 'package:pw_market_filter/features/instancias/domain/entrada_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _classes = {'Bardo', 'Mago'};

/// Uma gaveta que se pode partir de propósito, que é o caso que interessa.
class _Gaveta implements BrowserMemory {
  _Gaveta([this.valor]);

  String? valor;
  bool estoura = false;

  @override
  String? read() => estoura ? null : valor;

  @override
  void write(String v) => valor = v;
}

void main() {
  test('o plano sobrevive a gravar e ler', () {
    final gaveta = _Gaveta();
    final memoria = InstanciasMemoria(gaveta);

    memoria.gravar(
      PlanoDeInstancias(
        personagens: [
          PersonagemDeInstancia(
            nome: 'duhit',
            classe: 'Bardo',
            contagens: const {
              EntradaDeInstancia.artefato: 3,
              EntradaDeInstancia.chave: 14,
            },
          ),
        ],
      ),
    );

    final lido = memoria.ler(classesConhecidas: _classes);
    expect(lido.personagens.single.nome, 'duhit');
    expect(lido.personagens.single.de(EntradaDeInstancia.chave), 14);
    expect(lido.personagens.single.de(EntradaDeInstancia.arma), 0);
  });

  test('as contagens são gravadas pelo nome do enum, nunca pelo índice', () {
    // **Um enum reordenado trocaria as chaves pelas relíquias de toda a
    // gente**, em silêncio, no ficheiro que já estava gravado. É a mesma
    // armadilha do id de um atributo, que é uma posição.
    final gaveta = _Gaveta();
    InstanciasMemoria(gaveta).gravar(
      PlanoDeInstancias(
        personagens: [
          PersonagemDeInstancia(
            nome: 'x',
            classe: 'Mago',
            contagens: const {EntradaDeInstancia.chave: 7},
          ),
        ],
      ),
    );

    expect(gaveta.valor, contains('"chave":7'));
  });

  test('um ficheiro estragado é uma lista vazia e nunca um erro', () {
    expect(
      InstanciasMemoria(
        _Gaveta('isto não é json'),
      ).ler(classesConhecidas: _classes).vazio,
      isTrue,
    );
    expect(
      InstanciasMemoria(
        _Gaveta('{"não":"é lista"}'),
      ).ler(classesConhecidas: _classes).vazio,
      isTrue,
    );
  });

  test('uma gaveta que não abre começa com a lista vazia', () {
    // Um navegador com os dados do site bloqueados estoura só ao ser tocado.
    // Uma ferramenta de planeamento nunca vale uma página em branco — e é
    // por isso que o botão de link existe.
    final gaveta = _Gaveta('[]')..estoura = true;

    expect(
      InstanciasMemoria(gaveta).ler(classesConhecidas: _classes).vazio,
      isTrue,
    );
  });

  test('entradas sem nome ou de classe desconhecida são deitadas fora', () {
    final gaveta = _Gaveta(
      '[{"nome":"","classe":"Mago"},'
      '{"nome":"y","classe":"Nigromante"},'
      '{"nome":"bom","classe":"Mago","chave":2}]',
    );

    final lido = InstanciasMemoria(gaveta).ler(classesConhecidas: _classes);
    expect([for (final p in lido.personagens) p.nome], ['bom']);
  });

  test('o link aponta para a ferramenta e leva a lista', () {
    final memoria = InstanciasMemoria(_Gaveta());
    final link = memoria.link(
      const PlanoDeInstancias(
        personagens: [PersonagemDeInstancia(nome: 'duhit', classe: 'Bardo')],
      ),
    );

    expect(link, startsWith('https://portalpw.net/#/instancias?'));
    expect(link, contains('duhit'));
  });

  test('sem ninguém, o link é só o endereço da ferramenta', () {
    expect(
      InstanciasMemoria(_Gaveta()).link(const PlanoDeInstancias()),
      'https://portalpw.net/#/instancias',
    );
  });
}
