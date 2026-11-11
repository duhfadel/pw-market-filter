import 'entrada_de_instancia.dart';
import 'personagem_de_instancia.dart';
import 'plano_de_instancias.dart';

/// A lista inteira num endereço, para poder sair deste aparelho.
///
/// **É a única rede contra limpar o navegador.** O plano vive em
/// `localStorage`, que é por aparelho: trocar de telemóvel, abrir no
/// computador ou limpar os dados apagava semanas de contagem sem nada a
/// recuperá-las. Um link resolve os três sem conta, sem servidor e sem
/// guardarmos dados de ninguém — e de caminho torna a lista partilhável.
///
/// Um personagem por parâmetro `p`, repetido:
///
/// ```
/// /instancias?p=Bardo~3~1~2~14~duhit&p=Mago~0~0~1~2~Mulexta
///             └ classe              └ nome
/// ```
///
/// **O til e não os dois pontos**, pela razão que o link do filtro já
/// registou: o `Uri` escapa os dois pontos e os porcentos de um nome
/// codificado à mão, e o que sai é ilegível para quem decide se clica.
///
/// **E o nome vai no fim, que é o que o torna à prova de til.** Tudo antes
/// dele tem aridade fixa — uma classe e quatro números —, portanto o que
/// sobra depois da quinta separação *é* o nome, com tis lá dentro e tudo. Um
/// apelido que contenha `~` partiria qualquer formato que o pusesse no meio.
///
/// **A classe vai pelo nome e nunca por um índice.** Um índice é uma posição,
/// e uma posição muda no dia em que alguém reordenar a lista das classes —
/// com um link antigo a abrir calado no personagem errado. É a mesma regra
/// pela qual um atributo viaja pelo nome no link do filtro.
const _personagemParam = 'p';
const _separador = '~';

/// Quantos campos vêm antes do nome: a classe e as quatro contagens.
const _camposFixos = 1 + 4;

/// Um tecto, e ele existe para o endereço não ser a arma.
///
/// Uma lista de duzentos personagens escreveria um link que nenhum navegador
/// aceita e que nenhum campo de chat deixa colar. Cem é largo de mais para
/// qualquer conta real e curto o bastante para o link continuar a ser um
/// link.
const maximoDePersonagens = 100;

String encodeInstancias(PlanoDeInstancias plano) {
  final partes = <String>[];

  // Sempre a ordem de origem, nunca `emOrdem`. A ordenação é uma vista de
  // quem está a olhar; gravá-la no link entregaria ao próximo a lista
  // baralhada em vez da que o dono escreveu.
  for (final p in plano.personagens.take(maximoDePersonagens)) {
    final campos = [
      p.classe,
      for (final e in EntradaDeInstancia.values) '${p.de(e)}',
      p.nome,
    ].join(_separador);
    partes.add('$_personagemParam=${Uri.encodeQueryComponent(campos)}');
  }

  return partes.join('&');
}

/// Lê o que [encodeInstancias] escreveu, e deita fora o que não entender.
///
/// **Uma entrada estragada cai sozinha e não leva as outras.** Um link
/// cortado a meio por um cliente de chat é o caso normal disto, e perder um
/// personagem é melhor do que abrir a ferramenta vazia sem dizer porquê.
PlanoDeInstancias decodeInstancias(
  Map<String, List<String>> query, {
  required Set<String> classesConhecidas,
}) {
  final personagens = <PersonagemDeInstancia>[];

  for (final cru in query[_personagemParam] ?? const <String>[]) {
    // `_camposFixos` e não `.length`: o nome é o resto e pode ter tis.
    final campos = cru.split(_separador);
    if (campos.length < _camposFixos + 1) continue;

    final classe = campos.first;
    // Uma classe que este site não conhece não desenha ícone nenhum e não há
    // como adivinhar qual era — o mesmo que o filtro faz a um atributo que a
    // recolha já não tem.
    if (!classesConhecidas.contains(classe)) continue;

    final nome = campos.sublist(_camposFixos).join(_separador).trim();
    if (nome.isEmpty) continue;

    final contagens = <EntradaDeInstancia, int>{};
    var valido = true;
    for (var i = 0; i < EntradaDeInstancia.values.length; i++) {
      final n = int.tryParse(campos[1 + i]);
      // Negativo é tão inválido como letra: ninguém tem menos três chaves, e
      // aceitá-lo poria um número impossível na soma de baixo.
      if (n == null || n < 0) {
        valido = false;
        break;
      }
      contagens[EntradaDeInstancia.values[i]] = n;
    }
    if (!valido) continue;

    personagens.add(
      PersonagemDeInstancia(nome: nome, classe: classe, contagens: contagens),
    );
    if (personagens.length == maximoDePersonagens) break;
  }

  return PlanoDeInstancias(personagens: personagens);
}
