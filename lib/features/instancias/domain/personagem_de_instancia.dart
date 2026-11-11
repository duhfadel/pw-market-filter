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

  int de(EntradaDeInstancia entrada) => contagens[entrada] ?? 0;

  PersonagemDeInstancia com(EntradaDeInstancia entrada, int quantos) =>
      PersonagemDeInstancia(
        nome: nome,
        classe: classe,
        contagens: {...contagens, entrada: quantos < 0 ? 0 : quantos},
      );

  PersonagemDeInstancia renomeado(String novo) =>
      PersonagemDeInstancia(nome: novo, classe: classe, contagens: contagens);
}
