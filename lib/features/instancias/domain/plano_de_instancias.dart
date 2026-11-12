import 'entrada_de_instancia.dart';
import 'grupo_de_instancias.dart';
import 'personagem_de_instancia.dart';

/// Por onde a tabela está ordenada.
///
/// **A ordem é uma pergunta e não um enfeite**, que é a razão de ela existir:
/// a ferramenta nasceu de *quais é que têm mais e quais têm menos chaves*, e
/// sem ordenar isso responde-se a contar com o dedo. Com grupos, ordenar
/// ordena **dentro de cada grupo** — a gaveta é a unidade que se compara.
sealed class OrdemDoPlano {
  const OrdemDoPlano();
}

/// A ordem em que os personagens foram escritos. É a de origem, e é para onde
/// se volta: uma lista que não se consegue devolver ao estado de antes é uma
/// lista que perdeu informação — a ordem que o dono lhe deu, e que o arrastar
/// pode ter construído de propósito.
class OrdemDeEntrada extends OrdemDoPlano {
  const OrdemDeEntrada();
}

/// Do que tem mais para o que tem menos de uma coluna, dentro de cada grupo.
///
/// **Só decrescente, e isso é uma escolha.** Um segundo toque volta a
/// [OrdemDeEntrada] em vez de inverter: *quem tem menos chaves* responde-se
/// a olhar para o fim da mesma lista.
class OrdemPorEntrada extends OrdemDoPlano {
  const OrdemPorEntrada(this.entrada);

  final EntradaDeInstancia entrada;
}

/// Uma morada de personagem: em que grupo, e em que linha dentro dele.
///
/// **É o que o arrastar move.** Um índice de grupo e um índice de personagem,
/// os dois da lista **de origem** — nunca da ordenada. A tabela traduz o que
/// o dedo tocou nestes dois números antes de pedir qualquer mudança, pela
/// mesma razão que o card do streamer resolve o login antes de desenhar.
class Morada {
  const Morada(this.grupo, this.personagem);

  final int grupo;
  final int personagem;
}

/// Os grupos de alguém, e as contas sobre eles.
///
/// Imutável: cada mexida devolve um plano novo, como o `SearchQuery`. É o que
/// torna *desfazer* possível e o que mantém o estado uma coisa só, fácil de
/// gravar e de pôr num link.
///
/// **Há sempre pelo menos um grupo.** Um plano sem grupo nenhum não teria
/// onde pôr o primeiro personagem, e uma tela que pede *crie um grupo antes
/// de criar um personagem* faz o visitante trabalhar para a ferramenta em vez
/// do contrário. O primeiro grupo nasce com a lista — ver [inicial].
class PlanoDeInstancias {
  const PlanoDeInstancias({
    required this.grupos,
    this.ordem = const OrdemDeEntrada(),
  });

  final List<GrupoDeInstancias> grupos;
  final OrdemDoPlano ordem;

  /// O nome do grupo que nasce sozinho com uma lista nova. Genérico de
  /// propósito: a pessoa renomeia-o se quiser, e quem nunca criar um segundo
  /// grupo nem dá pela existência da camada.
  static const nomeInicial = 'Meus personagens';

  /// Uma lista nova: um grupo, vazio. Nunca `grupos: const []`.
  factory PlanoDeInstancias.inicial() =>
      const PlanoDeInstancias(grupos: [GrupoDeInstancias(nome: nomeInicial)]);

  /// Vazio quer dizer *nenhum personagem em grupo nenhum*, e não *nenhum
  /// grupo*. É o que decide se a tela mostra o convite ou a tabela.
  bool get vazio => grupos.every((g) => g.personagens.isEmpty);

  int get quantosPersonagens =>
      grupos.fold(0, (soma, g) => soma + g.personagens.length);

  /// Os personagens de um grupo como a tabela os desenha.
  ///
  /// **Ordenar é uma vista e nunca uma mudança na lista.** Cada
  /// [GrupoDeInstancias.personagens] guarda a ordem em que foram escritos (ou
  /// arrastados para lá), e é essa que é gravada e que viaja no link. Ordenar
  /// por chaves e recarregar a página não pode baralhar a gaveta para sempre.
  List<PersonagemDeInstancia> emOrdem(int grupo) {
    final lista = grupos[grupo].personagens;
    return switch (ordem) {
      OrdemDeEntrada() => lista,
      OrdemPorEntrada(:final entrada) =>
        [...lista]..sort((a, b) {
          final porEntrada = b.de(entrada).compareTo(a.de(entrada));
          // Empate decidido pela ordem de entrada e não pelo nome: dez
          // personagens com zero chaves não podem saltar de sítio só porque
          // alguém tocou num cabeçalho.
          return porEntrada != 0
              ? porEntrada
              : lista.indexOf(a).compareTo(lista.indexOf(b));
        }),
    };
  }

  /// O total geral de uma coisa, somando todos os grupos. É a linha de baixo
  /// de tudo, e a única resposta a *quantas chaves tenho ao todo*.
  int total(EntradaDeInstancia entrada) =>
      grupos.fold(0, (soma, g) => soma + g.total(entrada));

  PlanoDeInstancias _com(List<GrupoDeInstancias> novos) =>
      PlanoDeInstancias(grupos: novos, ordem: ordem);

  // --- grupos ---

  PlanoDeInstancias maisUmGrupo(String nome) =>
      _com([...grupos, GrupoDeInstancias(nome: nome.trim())]);

  PlanoDeInstancias renomeandoGrupo(int grupo, String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return this;
    return _trocandoGrupo(grupo, grupos[grupo].renomeado(limpo));
  }

  /// Tira um grupo e **tudo o que está dentro dele**.
  ///
  /// Nunca deixa o plano sem grupo nenhum: tirar o último devolve um plano
  /// inicial, não um vazio — ver [inicial] para porquê.
  PlanoDeInstancias semOGrupo(int grupo) {
    final sobra = [
      for (var i = 0; i < grupos.length; i++)
        if (i != grupo) grupos[i],
    ];
    return sobra.isEmpty
        ? PlanoDeInstancias(
            grupos: const [GrupoDeInstancias(nome: nomeInicial)],
            ordem: ordem,
          )
        : _com(sobra);
  }

  /// Repõe um grupo inteiro no lugar de onde saiu — o desfazer de
  /// [semOGrupo].
  PlanoDeInstancias inserindoGrupo(int grupo, GrupoDeInstancias quem) {
    final onde = grupo.clamp(0, grupos.length);
    return _com([...grupos.take(onde), quem, ...grupos.skip(onde)]);
  }

  // --- personagens ---

  PlanoDeInstancias maisUmPersonagem(int grupo, PersonagemDeInstancia quem) =>
      _trocandoGrupo(grupo, grupos[grupo].maisUm(quem));

  PlanoDeInstancias semOPersonagem(Morada onde) => _trocandoGrupo(
    onde.grupo,
    grupos[onde.grupo].com([
      for (var i = 0; i < grupos[onde.grupo].personagens.length; i++)
        if (i != onde.personagem) grupos[onde.grupo].personagens[i],
    ]),
  );

  /// Repõe um personagem no lugar exacto de onde saiu — o desfazer de
  /// [semOPersonagem]. O lugar é metade do trabalho: pô-lo no fim do grupo
  /// perderia a ordem que o dono lhe tinha dado.
  PlanoDeInstancias inserindoPersonagem(
    Morada onde,
    PersonagemDeInstancia quem,
  ) {
    final lista = grupos[onde.grupo].personagens;
    final idx = onde.personagem.clamp(0, lista.length);
    return _trocandoGrupo(
      onde.grupo,
      grupos[onde.grupo].com([...lista.take(idx), quem, ...lista.skip(idx)]),
    );
  }

  PlanoDeInstancias trocandoPersonagem(
    Morada onde,
    PersonagemDeInstancia novo,
  ) => _trocandoGrupo(
    onde.grupo,
    grupos[onde.grupo].com([
      for (var i = 0; i < grupos[onde.grupo].personagens.length; i++)
        if (i == onde.personagem) novo else grupos[onde.grupo].personagens[i],
    ]),
  );

  /// Move um personagem de um grupo para outro — o que o arrastar faz.
  ///
  /// **Tira primeiro, põe depois, e a ordem importa quando é o mesmo grupo.**
  /// Arrastar dentro da própria gaveta é reordenar, e tirar antes de calcular
  /// o destino é o que faz o índice de chegada apontar para a lista já sem o
  /// que saiu — senão mover o primeiro para o fim erraria por um.
  PlanoDeInstancias movendoPersonagem(
    Morada de,
    int paraGrupo,
    int paraIndice,
  ) {
    if (de.grupo < 0 || de.grupo >= grupos.length) return this;
    if (paraGrupo < 0 || paraGrupo >= grupos.length) return this;
    final quem = grupos[de.grupo].personagens[de.personagem];

    final semEle = semOPersonagem(de);
    // No mesmo grupo, um alvo depois da posição de origem recua um, porque a
    // lista encolheu à esquerda dele.
    final ajustado = de.grupo == paraGrupo && paraIndice > de.personagem
        ? paraIndice - 1
        : paraIndice;
    return semEle.inserindoPersonagem(Morada(paraGrupo, ajustado), quem);
  }

  PlanoDeInstancias contando(
    Morada onde,
    EntradaDeInstancia entrada,
    int quantos,
  ) => trocandoPersonagem(
    onde,
    grupos[onde.grupo].personagens[onde.personagem].com(entrada, quantos),
  );

  /// A coleta diária de um personagem: +1 em cada entrada, marcado em [hoje].
  /// Sem efeito se ele já pegou hoje.
  PlanoDeInstancias coletaDiaria(Morada onde, String hoje) =>
      trocandoPersonagem(
        onde,
        grupos[onde.grupo].personagens[onde.personagem].comColetaDiaria(hoje),
      );

  /// A coleta diária do grupo inteiro: cada personagem que ainda não pegou
  /// hoje soma as três entradas. Quem já pegou fica como está.
  PlanoDeInstancias coletaDiariaDoGrupo(int grupo, String hoje) =>
      _trocandoGrupo(
        grupo,
        grupos[grupo].com([
          for (final p in grupos[grupo].personagens) p.comColetaDiaria(hoje),
        ]),
      );

  PlanoDeInstancias renomeandoPersonagem(Morada onde, String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return this;
    return trocandoPersonagem(
      onde,
      grupos[onde.grupo].personagens[onde.personagem].renomeado(limpo),
    );
  }

  // --- ordem ---

  /// Um toque no cabeçalho de uma coluna. Ordena dentro de cada grupo; tocar
  /// outra vez na mesma volta à ordem de entrada.
  PlanoDeInstancias ordenandoPor(EntradaDeInstancia entrada) =>
      PlanoDeInstancias(
        grupos: grupos,
        ordem:
            ordem is OrdemPorEntrada &&
                (ordem as OrdemPorEntrada).entrada == entrada
            ? const OrdemDeEntrada()
            : OrdemPorEntrada(entrada),
      );

  PlanoDeInstancias _trocandoGrupo(int grupo, GrupoDeInstancias novo) => _com([
    for (var i = 0; i < grupos.length; i++)
      if (i == grupo) novo else grupos[i],
  ]);
}
