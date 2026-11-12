import 'entrada_de_instancia.dart';

/// Um personagem na lista de alguém, com o que ele carrega.
///
/// **Isto não tem nada que ver com o mercado.** Ninguém aqui está à venda:
/// são os personagens de quem está a ler, escritos à mão, e o site nunca os
/// viu nem os pode verificar. É por isso que a classe é escolhida e o nome é
/// escrito — não há de onde os ir buscar.
class PersonagemDeInstancia {
  const PersonagemDeInstancia({
    required this.nome,
    required this.classe,
    this.contagens = const {},
    this.coletadoEm,
  });

  /// O apelido, como o dono dele o escreve. Pode ser qualquer coisa — este
  /// campo nunca é comparado com nada.
  final String nome;

  /// Uma das dezassete, e serve para desenhar o ícone. É só isso: a
  /// ferramenta não sabe nem precisa de saber o que cada classe faz.
  final String classe;

  /// Quanto ele tem de cada coisa. **Ausente é zero**, e os dois são escritos
  /// iguais na tela — ao contrário do card do mercado, onde `carrega 0` e
  /// *não foi lido* são factos diferentes. Aqui quem escreve é o dono: se não
  /// escreveu nada, tem zero, e não há terceira hipótese.
  final Map<EntradaDeInstancia, int> contagens;

  /// O dia em que se pegou a coleta diária deste personagem pela última vez,
  /// como `AAAA-MM-DD` no fuso do Brasil — ou `null` se nunca.
  ///
  /// **É uma data e não um booleano de propósito.** Um *já pegou* sem data
  /// nunca se apagaria sozinho: amanhã continuaria a dizer que já pegou. A
  /// data compara-se com o dia de hoje e vira *pode pegar* à meia-noite do
  /// Brasil sem ninguém lhe tocar — a mesma razão pela qual o selo *novo* dos
  /// guias carrega uma data em vez de uma bandeira.
  final String? coletadoEm;

  int de(EntradaDeInstancia entrada) => contagens[entrada] ?? 0;

  /// Se a coleta diária já foi feita no dia [hoje].
  bool pegouEm(String hoje) => coletadoEm == hoje;

  PersonagemDeInstancia com(EntradaDeInstancia entrada, int quantos) =>
      PersonagemDeInstancia(
        nome: nome,
        classe: classe,
        contagens: {...contagens, entrada: quantos < 0 ? 0 : quantos},
        coletadoEm: coletadoEm,
      );

  PersonagemDeInstancia renomeado(String novo) => PersonagemDeInstancia(
    nome: novo,
    classe: classe,
    contagens: contagens,
    coletadoEm: coletadoEm,
  );

  /// Pega as três entradas do dia: +1 em cada Relíquia Maravilha, e marca
  /// [coletadoEm] como [hoje]. A Chave não entra — a coleta diária dá
  /// entradas, não chaves.
  ///
  /// **Idempotente no dia.** Se já pegou hoje, devolve-se a si próprio sem
  /// somar nada — é o que impede dois cliques de valerem seis entradas, e o
  /// que deixa o botão do grupo passar por quem já pegou sem o penalizar.
  PersonagemDeInstancia comColetaDiaria(String hoje) {
    if (pegouEm(hoje)) return this;
    return PersonagemDeInstancia(
      nome: nome,
      classe: classe,
      contagens: {
        ...contagens,
        for (final e in EntradaDeInstancia.entradas) e: de(e) + 1,
      },
      coletadoEm: hoje,
    );
  }
}
