import 'entrada_de_instancia.dart';
import 'personagem_de_instancia.dart';

/// Por onde a tabela está ordenada.
///
/// **A ordem é uma pergunta e não um enfeite**, que é a razão de ela existir:
/// a ferramenta nasceu de *quais é que têm mais e quais têm menos chaves*, e
/// sem ordenar isso responde-se a contar com o dedo.
sealed class OrdemDoPlano {
  const OrdemDoPlano();
}

/// A ordem em que os personagens foram escritos. É a de origem, e é para onde
/// se volta: uma lista que não se consegue devolver ao estado de antes é uma
/// lista que perdeu informação — a ordem que o dono lhe deu.
class OrdemDeEntrada extends OrdemDoPlano {
  const OrdemDeEntrada();
}

/// Do que tem mais para o que tem menos de uma coluna.
///
/// **Só decrescente, e isso é uma escolha.** Um segundo toque volta a
/// [OrdemDeEntrada] em vez de inverter: *quem tem menos chaves* responde-se
/// a olhar para o fim da mesma lista, portanto uma ordem crescente seria um
/// terceiro estado para dizer o que o primeiro já diz de baixo para cima.
class OrdemPorEntrada extends OrdemDoPlano {
  const OrdemPorEntrada(this.entrada);

  final EntradaDeInstancia entrada;
}

/// A lista de personagens de alguém, e as contas sobre ela.
///
/// Imutável: cada mexida devolve um plano novo, como o `SearchQuery`. É o que
/// torna *desfazer* possível mais tarde sem refazer nada.
class PlanoDeInstancias {
  const PlanoDeInstancias({
    this.personagens = const [],
    this.ordem = const OrdemDeEntrada(),
  });

  final List<PersonagemDeInstancia> personagens;
  final OrdemDoPlano ordem;

  bool get vazio => personagens.isEmpty;

  /// Os personagens como a tabela os desenha.
  ///
  /// **Ordenar é uma vista e nunca uma mudança na lista.** [personagens]
  /// guarda a ordem em que foram escritos, e é essa que é gravada e que viaja
  /// no link — ordenar por chaves e recarregar a página não pode deixar
  /// alguém com a lista baralhada para sempre.
  List<PersonagemDeInstancia> get emOrdem => switch (ordem) {
    OrdemDeEntrada() => personagens,
    OrdemPorEntrada(:final entrada) =>
      [...personagens]..sort((a, b) {
        final porEntrada = b.de(entrada).compareTo(a.de(entrada));
        // Empate decidido pela ordem de entrada e não pelo nome: dez
        // personagens com zero chaves não podem saltar de sítio só porque
        // alguém tocou num cabeçalho.
        return porEntrada != 0
            ? porEntrada
            : personagens.indexOf(a).compareTo(personagens.indexOf(b));
      }),
  };

  /// Quanto é que a conta toda tem de uma coisa. É a linha de baixo da tabela
  /// e a única resposta que nenhuma linha sozinha dá.
  int total(EntradaDeInstancia entrada) =>
      personagens.fold(0, (soma, p) => soma + p.de(entrada));

  PlanoDeInstancias comPersonagens(List<PersonagemDeInstancia> novos) =>
      PlanoDeInstancias(personagens: novos, ordem: ordem);

  PlanoDeInstancias maisUm(PersonagemDeInstancia quem) =>
      comPersonagens([...personagens, quem]);

  /// Põe alguém de volta no lugar de onde saiu.
  ///
  /// **Existe para o desfazer, e o lugar é metade do trabalho.** Repor no fim
  /// devolveria o personagem e perderia a ordem que o dono lhe tinha dado —
  /// que é, ela própria, informação que ninguém mais tem.
  PlanoDeInstancias inserindo(int indice, PersonagemDeInstancia quem) {
    final onde = indice.clamp(0, personagens.length);
    return comPersonagens([
      ...personagens.take(onde),
      quem,
      ...personagens.skip(onde),
    ]);
  }

  PlanoDeInstancias semO(int indice) => comPersonagens([
    for (var i = 0; i < personagens.length; i++)
      if (i != indice) personagens[i],
  ]);

  /// Troca um personagem no lugar onde ele está.
  ///
  /// Por índice da lista **de origem** e não da ordenada: a tabela resolve
  /// essa tradução antes de chamar, porque é ela que sabe o que o dedo tocou.
  PlanoDeInstancias trocando(int indice, PersonagemDeInstancia novo) =>
      comPersonagens([
        for (var i = 0; i < personagens.length; i++)
          if (i == indice) novo else personagens[i],
      ]);

  /// Um toque no cabeçalho de uma coluna.
  ///
  /// Ordena por ela; tocar outra vez na mesma volta à ordem de entrada. Ver
  /// [OrdemPorEntrada] para porque não há terceiro estado.
  PlanoDeInstancias ordenandoPor(EntradaDeInstancia entrada) =>
      PlanoDeInstancias(
        personagens: personagens,
        ordem:
            ordem is OrdemPorEntrada &&
                (ordem as OrdemPorEntrada).entrada == entrada
            ? const OrdemDeEntrada()
            : OrdemPorEntrada(entrada),
      );
}
