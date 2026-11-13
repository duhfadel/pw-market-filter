import 'dart:convert';

import '../../../core/memoria/browser_memory.dart';
import '../domain/campo_personalizado.dart';
import '../domain/entrada_de_instancia.dart';
import '../domain/grupo_de_instancias.dart';
import '../domain/instancias_url.dart';
import '../domain/personagem_de_instancia.dart';
import '../domain/plano_de_instancias.dart';

/// O plano, guardado neste navegador.
///
/// **Guardado como JSON e não como o link**, apesar de os dois saberem
/// escrever a mesma coisa. São dois trabalhos diferentes: o link é para um
/// humano ver e colar, portanto tem tecto e abrevia; isto é um ficheiro, não
/// tem tecto e pode ganhar campos sem ter de caber num endereço.
///
/// **Falha calada nos dois sentidos**, como tudo o que toca `localStorage`
/// aqui: um navegador com os dados do site bloqueados estoura só ao ser
/// tocado, e uma ferramenta de planeamento nunca vale uma página em branco.
/// Não conseguir ler é começar com uma lista inicial — e é por isso que o
/// botão de link existe.
class InstanciasMemoria {
  InstanciasMemoria(BrowserMemory memoria) : _memoria = memoria;

  final BrowserMemory _memoria;

  /// O nome da gaveta. Prefixado para nunca colidir com as outras chaves que
  /// este site já escreve no mesmo `localStorage`.
  static const chave = 'pw.instancias';

  PlanoDeInstancias ler({required Set<String> classesConhecidas}) {
    final cru = _memoria.read();
    if (cru == null || cru.isEmpty) return PlanoDeInstancias.inicial();

    try {
      final lido = jsonDecode(cru);
      if (lido is! List) return PlanoDeInstancias.inicial();

      final grupos = <GrupoDeInstancias>[];
      for (final g in lido) {
        if (g is! Map) continue;
        final nome = (g['nome'] as String?)?.trim();
        if (nome == null || nome.isEmpty) continue;

        final personagens = <PersonagemDeInstancia>[];
        for (final p in (g['personagens'] as List? ?? const [])) {
          if (p is! Map) continue;
          final pnome = (p['nome'] as String?)?.trim() ?? '';
          final classe = p['classe'] as String?;
          if (pnome.isEmpty || !classesConhecidas.contains(classe)) continue;
          final contagens = <EntradaDeInstancia, int>{};
          for (final e in EntradaDeInstancia.values) {
            final n = (p[e.name] as num?)?.toInt() ?? 0;
            contagens[e] = n < 0 ? 0 : n;
          }
          final cru = p['coletadoEm'];
          final coletadoEm =
              cru is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cru)
              ? cru
              : null;
          final extras = <String, String>{};
          final extrasCru = p['extras'];
          if (extrasCru is Map) {
            for (final e in extrasCru.entries) {
              final k = e.key;
              final v = e.value;
              if (k is String && v is String && v.isNotEmpty) extras[k] = v;
            }
          }
          personagens.add(
            PersonagemDeInstancia(
              nome: pnome,
              classe: classe!,
              contagens: contagens,
              coletadoEm: coletadoEm,
              extras: extras,
            ),
          );
        }
        grupos.add(GrupoDeInstancias(nome: nome, personagens: personagens));
      }

      final campos = _lerCampos(lido);

      // Um ficheiro sem grupo válido nenhum é tão bom como nenhum ficheiro —
      // a tela precisa sempre de ter onde pôr o primeiro personagem. Os campos
      // vêm à parte, num segundo elemento da lista do topo (ver `gravar`).
      return grupos.isEmpty
          ? PlanoDeInstancias.inicial()
          : PlanoDeInstancias(grupos: grupos, campos: campos);
    } catch (_) {
      return PlanoDeInstancias.inicial();
    }
  }

  void gravar(PlanoDeInstancias plano) {
    // A ordem de origem, nunca a ordenada — a mesma regra do link.
    //
    // **O topo é uma lista de dois: os grupos, e depois um objecto com os
    // campos personalizados.** Os campos são globais ao plano, não de um
    // grupo, portanto vivem fora da lista de grupos. O objecto no fim é
    // opcional: um ficheiro antigo sem ele lê-se com zero campos.
    final grupos = [
      for (final g in plano.grupos)
        {
          'nome': g.nome,
          'personagens': [
            for (final p in g.personagens)
              {
                'nome': p.nome,
                'classe': p.classe,
                // Por nome do valor do enum e nunca pelo índice: um enum
                // reordenado trocaria as chaves pelas relíquias de toda a
                // gente, em silêncio, no ficheiro que já estava gravado.
                for (final e in EntradaDeInstancia.values) e.name: p.de(e),
                // Só quando há: um dia sem coleta não escreve a chave, para
                // o ficheiro não encher de nulos.
                if (p.coletadoEm != null) 'coletadoEm': p.coletadoEm,
                if (p.extras.isNotEmpty) 'extras': p.extras,
              },
          ],
        },
    ];
    _memoria.write(
      jsonEncode([
        ...grupos,
        if (plano.campos.isNotEmpty)
          {
            'campos': [
              for (final c in plano.campos)
                {
                  'id': c.id,
                  'nome': c.nome,
                  'tipo': c.tipo.sigla,
                  if (c.opcoes.isNotEmpty) 'opcoes': c.opcoes,
                },
            ],
          },
      ]),
    );
  }

  /// Lê os campos personalizados do objecto `{'campos': [...]}` que `gravar`
  /// põe no fim da lista do topo. Qualquer elemento da lista que não seja um
  /// grupo nem este objecto é ignorado — robusto a lixo.
  List<CampoPersonalizado> _lerCampos(List lido) {
    for (final item in lido) {
      if (item is! Map || item['campos'] is! List) continue;
      final campos = <CampoPersonalizado>[];
      for (final c in item['campos'] as List) {
        if (c is! Map) continue;
        final id = c['id'];
        final nome = (c['nome'] as String?)?.trim();
        final tipo = CampoTipo.daSigla(c['tipo'] as String? ?? '');
        if (id is! String ||
            id.isEmpty ||
            nome == null ||
            nome.isEmpty ||
            tipo == null) {
          continue;
        }
        final opcoes = <String>[
          for (final o in (c['opcoes'] as List? ?? const []))
            if (o is String && o.isNotEmpty) o,
        ];
        campos.add(
          CampoPersonalizado(id: id, nome: nome, tipo: tipo, opcoes: opcoes),
        );
      }
      return campos;
    }
    return const [];
  }

  /// O que o botão *copiar link* põe na área de transferência.
  String link(PlanoDeInstancias plano) {
    final query = encodeInstancias(plano);
    return 'https://portalpw.net/#/instancias${query.isEmpty ? '' : '?$query'}';
  }
}
