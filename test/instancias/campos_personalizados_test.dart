import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/memoria/browser_memory.dart';
import 'package:pw_market_filter/features/instancias/data/instancias_memoria.dart';
import 'package:pw_market_filter/features/instancias/domain/campo_personalizado.dart';
import 'package:pw_market_filter/features/instancias/domain/grupo_de_instancias.dart';
import 'package:pw_market_filter/features/instancias/domain/instancias_url.dart';
import 'package:pw_market_filter/features/instancias/domain/personagem_de_instancia.dart';
import 'package:pw_market_filter/features/instancias/domain/plano_de_instancias.dart';

const _classes = {'Bardo', 'Mago'};

Map<String, List<String>> _q(String s) =>
    Uri.parse('/instancias?$s').queryParametersAll;

class _Gaveta implements BrowserMemory {
  String? valor;
  @override
  String? read() => valor;
  @override
  void write(String v) => valor = v;
}

PlanoDeInstancias _plano() => PlanoDeInstancias(
  grupos: [
    GrupoDeInstancias(
      nome: 'A',
      personagens: [
        const PersonagemDeInstancia(nome: 'duhit', classe: 'Bardo'),
        const PersonagemDeInstancia(nome: 'farmante', classe: 'Mago'),
      ],
    ),
  ],
);

void main() {
  test('criar campos gera ids únicos e distintos por tipo', () {
    final p = _plano()
        .maisUmCampo('TW?', CampoTipo.marcacao)
        .maisUmCampo('Obs', CampoTipo.nota)
        .maisUmCampo(
          'Status',
          CampoTipo.escolha,
          opcoes: ['Ativo', 'Vendendo'],
        );

    expect(p.campos.length, 3);
    expect(p.campos.map((c) => c.id).toSet().length, 3, reason: 'ids únicos');
    expect(p.campos[2].opcoes, ['Ativo', 'Vendendo']);
  });

  test('marcar um campo num personagem, e contar quantos marcaram', () {
    var p = _plano().maisUmCampo('TW?', CampoTipo.marcacao);
    final id = p.campos.single.id;

    p = p.comExtra(const Morada(0, 0), id, '1');
    expect(p.grupos[0].personagens[0].marcado(id), isTrue);
    expect(p.grupos[0].personagens[1].marcado(id), isFalse);
    expect(p.marcados(id), 1);

    // Limpar com valor vazio apaga a chave — ausente é não preenchido.
    p = p.comExtra(const Morada(0, 0), id, '');
    expect(p.grupos[0].personagens[0].marcado(id), isFalse);
    expect(p.grupos[0].personagens[0].extras.containsKey(id), isFalse);
    expect(p.marcados(id), 0);
  });

  test('apagar um campo limpa o valor dele em todos os personagens', () {
    var p = _plano().maisUmCampo('Obs', CampoTipo.nota);
    final id = p.campos.single.id;
    p = p
        .comExtra(const Morada(0, 0), id, 'trocar arma')
        .comExtra(const Morada(0, 1), id, 'vender');

    p = p.semOCampo(id);
    expect(p.campos, isEmpty);
    expect(p.grupos[0].personagens[0].extras.containsKey(id), isFalse);
    expect(p.grupos[0].personagens[1].extras.containsKey(id), isFalse);
  });

  test('os campos e os valores sobrevivem ao link, com til no valor', () {
    var p = _plano()
        .maisUmCampo('TW?', CampoTipo.marcacao)
        .maisUmCampo(
          'Status',
          CampoTipo.escolha,
          opcoes: ['Ativo', 'Vai~vender'],
        );
    final tw = p.campos[0].id;
    final status = p.campos[1].id;
    p = p
        .comExtra(const Morada(0, 0), tw, '1')
        .comExtra(const Morada(0, 1), status, 'Vai~vender');

    final v = decodeInstancias(
      _q(encodeInstancias(p)),
      classesConhecidas: _classes,
    )!;

    expect(v.campos.length, 2);
    expect(v.campos[1].opcoes, [
      'Ativo',
      'Vai~vender',
    ], reason: 'opção com til');
    expect(v.grupos[0].personagens[0].marcado(tw), isTrue);
    expect(v.grupos[0].personagens[1].extra(status), 'Vai~vender');
  });

  test('uma nota com til e espaços sobrevive ao link', () {
    var p = _plano().maisUmCampo('Obs', CampoTipo.nota);
    final id = p.campos.single.id;
    p = p.comExtra(const Morada(0, 0), id, 'trocar ~arma~ antes de vender');

    final v = decodeInstancias(
      _q(encodeInstancias(p)),
      classesConhecidas: _classes,
    )!;
    expect(
      v.grupos[0].personagens[0].extra(id),
      'trocar ~arma~ antes de vender',
    );
  });

  test('os campos e valores sobrevivem a gravar e ler do disco', () {
    final g = _Gaveta();
    var p = _plano()
        .maisUmCampo('TW?', CampoTipo.marcacao)
        .maisUmCampo('Obs', CampoTipo.nota);
    final tw = p.campos[0].id;
    final obs = p.campos[1].id;
    p = p
        .comExtra(const Morada(0, 0), tw, '1')
        .comExtra(const Morada(0, 1), obs, 'nota aqui');

    InstanciasMemoria(g).gravar(p);
    final lido = InstanciasMemoria(g).ler(classesConhecidas: _classes);

    expect(lido.campos.map((c) => c.nome), ['TW?', 'Obs']);
    expect(lido.grupos[0].personagens[0].marcado(tw), isTrue);
    expect(lido.grupos[0].personagens[1].extra(obs), 'nota aqui');
  });

  test('um valor órfão (campo que não existe) cai na leitura do link', () {
    // id 'z9' não corresponde a campo nenhum definido.
    final v = decodeInstancias(
      _q('g=A&cf=0~c~TW?&p=0~Bardo~0~0~0~0~~duhit&x=0~z9~lixo'),
      classesConhecidas: _classes,
    )!;
    expect(v.grupos[0].personagens[0].extras, isEmpty);
    expect(v.campos.single.nome, 'TW?');
  });
}
