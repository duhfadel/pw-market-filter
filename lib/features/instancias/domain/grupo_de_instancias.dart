import 'entrada_de_instancia.dart';
import 'personagem_de_instancia.dart';

/// Uma gaveta nomeada de personagens.
///
/// **O nome é livre e é o único campo que o grupo tem de seu.** A pessoa
/// escreve o que quiser — *Conta principal*, *Mulas de TW*, *Do meu irmão* —
/// e a ferramenta não presume nada sobre o que isso significa. Um grupo não
/// conta chaves nem relíquias: isso é dos personagens. Ele só os arruma, e a
/// soma dele é a soma deles.
class GrupoDeInstancias {
  const GrupoDeInstancias({required this.nome, this.personagens = const []});

  final String nome;
  final List<PersonagemDeInstancia> personagens;

  /// Quanto este grupo tem de uma coisa — a soma dos seus. É o subtotal que
  /// a tabela desenha debaixo de cada grupo.
  int total(EntradaDeInstancia entrada) =>
      personagens.fold(0, (soma, p) => soma + p.de(entrada));

  GrupoDeInstancias com(List<PersonagemDeInstancia> novos) =>
      GrupoDeInstancias(nome: nome, personagens: novos);

  GrupoDeInstancias renomeado(String novo) =>
      GrupoDeInstancias(nome: novo, personagens: personagens);

  GrupoDeInstancias maisUm(PersonagemDeInstancia quem) =>
      com([...personagens, quem]);
}
