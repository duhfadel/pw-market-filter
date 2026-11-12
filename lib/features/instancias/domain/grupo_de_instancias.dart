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

  /// Quantos ainda não pegaram a coleta de [hoje] — o que o botão do grupo
  /// vai somar se for carregado.
  int faltamHoje(String hoje) =>
      personagens.where((p) => !p.pegouEm(hoje)).length;

  /// Se todos já pegaram hoje. Um grupo vazio devolve `false`: não há nada
  /// para pegar, portanto o botão fica apagado em vez de dizer *todos
  /// pegaram* sobre ninguém.
  bool todosPegaramHoje(String hoje) =>
      personagens.isNotEmpty && personagens.every((p) => p.pegouEm(hoje));

  GrupoDeInstancias com(List<PersonagemDeInstancia> novos) =>
      GrupoDeInstancias(nome: nome, personagens: novos);

  GrupoDeInstancias renomeado(String novo) =>
      GrupoDeInstancias(nome: novo, personagens: personagens);

  GrupoDeInstancias maisUm(PersonagemDeInstancia quem) =>
      com([...personagens, quem]);
}
