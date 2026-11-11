import 'entrada_de_instancia.dart';
import 'grupo_de_instancias.dart';
import 'personagem_de_instancia.dart';
import 'plano_de_instancias.dart';

/// Os grupos e os personagens num endereço, para poderem sair deste aparelho.
///
/// **É a única rede contra limpar o navegador.** O plano vive em
/// `localStorage`, que é por aparelho: trocar de telemóvel, abrir no
/// computador ou limpar os dados apagava semanas de contagem sem nada a
/// recuperá-las. Um link resolve os três sem conta, sem servidor e sem
/// guardarmos dados de ninguém — e de caminho torna a lista partilhável.
///
/// Os grupos vêm primeiro, em ordem; cada personagem diz a que grupo
/// pertence pelo índice:
///
/// ```
/// /instancias?g=Principal&g=Mula
///            &p=0~Bardo~3~1~2~14~duhit
///            &p=1~Mago~0~0~1~2~mula1
/// ```
///
/// **O índice do grupo é o primeiro campo e um inteiro**, e aqui um índice é
/// seguro ao contrário da classe: ele é resolvido **dentro do próprio link**,
/// contra a lista de `g` que viaja ao lado, e não contra uma recolha que
/// mudou noutro dia. A classe viaja pelo nome pela razão oposta — ela é
/// resolvida contra o jogo, que é externo ao link.
///
/// **O nome vai no fim, que é o que o torna à prova de til.** Tudo antes dele
/// tem aridade fixa — o índice do grupo, a classe e quatro números — portanto
/// o que sobra depois da sexta separação *é* o nome, com tis lá dentro e
/// tudo. O nome do grupo passa por `Uri.encodeQueryComponent` sozinho, no seu
/// próprio parâmetro, portanto nunca precisa de ser separado de mais nada.
const _grupoParam = 'g';
const _personagemParam = 'p';
const _separador = '~';

/// Quantos campos vêm antes do nome do personagem: o índice do grupo, a
/// classe e as quatro contagens.
const _camposFixos = 1 + 1 + 4;

/// Tectos, para o endereço não ser a arma. Um link que nenhum navegador
/// aceita e que nenhum campo de chat deixa colar não é um link. Largos de
/// mais para qualquer conta real e curtos o bastante para continuar a ser um
/// link.
const maximoDeGrupos = 30;
const maximoDePersonagens = 200;

String encodeInstancias(PlanoDeInstancias plano) {
  final partes = <String>[];

  // Sempre a ordem de origem, nunca `emOrdem`: a ordenação é uma vista de
  // quem está a olhar, e gravá-la entregaria ao próximo a lista baralhada.
  final grupos = plano.grupos.take(maximoDeGrupos).toList();
  for (final g in grupos) {
    partes.add('$_grupoParam=${Uri.encodeQueryComponent(g.nome)}');
  }

  var escritos = 0;
  for (var gi = 0; gi < grupos.length; gi++) {
    for (final p in grupos[gi].personagens) {
      if (escritos >= maximoDePersonagens) break;
      final campos = [
        '$gi',
        p.classe,
        for (final e in EntradaDeInstancia.values) '${p.de(e)}',
        p.nome,
      ].join(_separador);
      partes.add('$_personagemParam=${Uri.encodeQueryComponent(campos)}');
      escritos++;
    }
  }

  return partes.join('&');
}

/// Lê o que [encodeInstancias] escreveu, e deita fora o que não entender.
///
/// **Uma entrada estragada cai sozinha e não leva as outras.** Um link
/// cortado a meio por um cliente de chat é o caso normal disto, e perder um
/// personagem é melhor do que abrir a ferramenta vazia sem dizer porquê.
///
/// `queryParametersAll` preserva a ordem **dentro** de cada chave, portanto a
/// lista de `g` chega na ordem em que foi escrita e o índice que cada `p`
/// carrega aponta para ela com segurança.
PlanoDeInstancias? decodeInstancias(
  Map<String, List<String>> query, {
  required Set<String> classesConhecidas,
}) {
  final nomes = (query[_grupoParam] ?? const <String>[])
      .take(maximoDeGrupos)
      .toList();
  if (nomes.isEmpty) return null;

  final personagensPorGrupo = <int, List<PersonagemDeInstancia>>{};
  var total = 0;

  for (final cru in query[_personagemParam] ?? const <String>[]) {
    if (total >= maximoDePersonagens) break;
    // `_camposFixos` e não `.length`: o nome é o resto e pode ter tis.
    final campos = cru.split(_separador);
    if (campos.length < _camposFixos + 1) continue;

    final grupo = int.tryParse(campos[0]);
    // Um índice fora da lista de grupos é lixo de um link cortado — cai, não
    // se inventa um grupo para o acolher.
    if (grupo == null || grupo < 0 || grupo >= nomes.length) continue;

    final classe = campos[1];
    // Uma classe que este site não conhece não desenha ícone nenhum e não há
    // como adivinhar qual era — o mesmo que o filtro faz a um atributo que a
    // recolha já não tem.
    if (!classesConhecidas.contains(classe)) continue;

    final nome = campos.sublist(_camposFixos).join(_separador).trim();
    if (nome.isEmpty) continue;

    final contagens = <EntradaDeInstancia, int>{};
    var valido = true;
    for (var i = 0; i < EntradaDeInstancia.values.length; i++) {
      final n = int.tryParse(campos[2 + i]);
      // Negativo é tão inválido como letra: ninguém tem menos três chaves.
      if (n == null || n < 0) {
        valido = false;
        break;
      }
      contagens[EntradaDeInstancia.values[i]] = n;
    }
    if (!valido) continue;

    personagensPorGrupo
        .putIfAbsent(grupo, () => [])
        .add(
          PersonagemDeInstancia(
            nome: nome,
            classe: classe,
            contagens: contagens,
          ),
        );
    total++;
  }

  return PlanoDeInstancias(
    grupos: [
      for (var i = 0; i < nomes.length; i++)
        GrupoDeInstancias(
          nome: nomes[i],
          personagens: personagensPorGrupo[i] ?? const [],
        ),
    ],
  );
}
