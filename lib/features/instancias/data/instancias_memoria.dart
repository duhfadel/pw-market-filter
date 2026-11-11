import 'dart:convert';

import '../../../core/memoria/browser_memory.dart';
import '../domain/entrada_de_instancia.dart';
import '../domain/instancias_url.dart';
import '../domain/personagem_de_instancia.dart';
import '../domain/plano_de_instancias.dart';

/// O plano, guardado neste navegador.
///
/// **Guardado como JSON e não como o link**, apesar de o link já saber
/// escrever a mesma coisa. São dois trabalhos diferentes: o link é para um
/// humano ver e colar, portanto tem tecto e abrevia; isto é um ficheiro, não
/// tem tecto e pode ganhar campos sem ter de caber num endereço. Juntá-los
/// daria uma das duas coisas mal feita.
///
/// **Falha calada nos dois sentidos**, como tudo o que toca `localStorage`
/// aqui: um navegador com os dados do site bloqueados estoura só ao ser
/// tocado, e uma ferramenta de planeamento nunca vale uma página em branco.
/// Não conseguir ler é começar com a lista vazia — e é por isso que o botão
/// de link existe.
class InstanciasMemoria {
  InstanciasMemoria(BrowserMemory memoria) : _memoria = memoria;

  final BrowserMemory _memoria;

  /// O nome da gaveta. Prefixado para nunca colidir com as outras duas chaves
  /// que este site já escreve no mesmo `localStorage`.
  static const chave = 'pw.instancias';

  PlanoDeInstancias ler({required Set<String> classesConhecidas}) {
    final cru = _memoria.read();
    if (cru == null || cru.isEmpty) return const PlanoDeInstancias();

    try {
      final lido = jsonDecode(cru);
      if (lido is! List) return const PlanoDeInstancias();

      final personagens = <PersonagemDeInstancia>[];
      for (final item in lido) {
        if (item is! Map) continue;
        final nome = (item['nome'] as String?)?.trim() ?? '';
        final classe = item['classe'] as String?;
        if (nome.isEmpty || !classesConhecidas.contains(classe)) continue;

        final contagens = <EntradaDeInstancia, int>{};
        for (final e in EntradaDeInstancia.values) {
          final n = (item[e.name] as num?)?.toInt() ?? 0;
          contagens[e] = n < 0 ? 0 : n;
        }
        personagens.add(
          PersonagemDeInstancia(
            nome: nome,
            classe: classe!,
            contagens: contagens,
          ),
        );
      }
      return PlanoDeInstancias(personagens: personagens);
    } catch (_) {
      // Um ficheiro estragado é uma lista vazia e nunca um erro na cara de
      // quem abriu a página.
      return const PlanoDeInstancias();
    }
  }

  void gravar(PlanoDeInstancias plano) {
    // A ordem de origem, nunca a ordenada — a mesma regra do link.
    _memoria.write(
      jsonEncode([
        for (final p in plano.personagens)
          {
            'nome': p.nome,
            'classe': p.classe,
            // Por nome do valor do enum e nunca pelo índice: um enum
            // reordenado trocaria as chaves pelas relíquias de toda a gente,
            // em silêncio, no ficheiro que já estava gravado.
            for (final e in EntradaDeInstancia.values) e.name: p.de(e),
          },
      ]),
    );
  }

  /// O que o botão *copiar link* põe na área de transferência.
  String link(PlanoDeInstancias plano) {
    final query = encodeInstancias(plano);
    return 'https://portalpw.net/#/instancias${query.isEmpty ? '' : '?$query'}';
  }
}
