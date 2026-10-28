import '../../../core/rotas.dart' as rotas;
import '../../../market/index_repository.dart' show IndexRepository;
import '../../../market/versoes.dart';

/// One door on the choice screen: a version the site knows about, merged
/// with whatever `versoes.json` says about it today.
///
/// The known versions are listed by hand in [portasDe] rather than derived
/// from the file, because a version with no collection yet has no row there
/// at all — `pw126` right now, see `web/versoes.json`'s real shape — and its
/// door still has to exist, dimmed. The same rule `Tool.isReady` already
/// applies to the front page's menu.
class Porta {
  const Porta({
    required this.chave,
    required this.nome,
    required this.rota,
    required this.descricao,
    this.resumo,
  });

  /// Matches `IndexRepository.pw187`/`pw126` and `VersaoResumo.chave`.
  final String chave;

  /// The readable name shown on the door — '1.8.7', '1.2.6'. A numeral, not a
  /// title: it stays on the body face wherever it is drawn, never Marcellus.
  final String nome;

  /// Where tapping the door goes — the version's own home, from
  /// `core/rotas.dart` —, ou **nulo numa versão que o site ainda não serve**.
  ///
  /// Nulo e não uma rota inventada: `/1.4.4` cairia no ecrã de escolha, e uma
  /// porta que se abre para o sítio onde já se está é pior do que uma porta
  /// fechada. É a mesma armadilha do `tem_ficha` do mapa de guerras, onde um
  /// território clicável abria uma ficha vazia.
  final String? rota;

  /// Uma frase sobre o servidor, escrita pelo dono.
  ///
  /// **Existe porque a tela pergunta *qual mercado* e só respondia com
  /// números.** Quantos personagens há à venda e quando foi a coleta dizem o
  /// tamanho da loja; não dizem nada sobre o jogo que está lá dentro, que é a
  /// única coisa que um visitante novo precisa para decidir. Pedida pelo dono
  /// em 28/10/2026.
  final String descricao;

  /// What the last collection for this version found, or `null` before the
  /// first one has ever run — the state that draws this door dimmed.
  final VersaoResumo? resumo;

  /// **As duas metades, e não só a coleta.** Uma porta só abre quando há um
  /// mercado colhido *e* uma rota para o servir. Com `pronta` a olhar só o
  /// resumo, bastaria alguém acrescentar uma linha a `versoes.json` para a
  /// porta do 1.4.4 ficar clicável e levar a lado nenhum — e a lição do
  /// `tem_ficha` é precisamente que a condição de mostrar tem de ser a mesma
  /// que a de renderizar.
  bool get pronta => resumo != null && rota != null;
}

/// Every door the site shows, in the order it shows them — **por ordem de
/// versão, do 1.2.6 ao 1.8.7**, escolha do dono em 12/10/2026.
///
/// Era o 1.8.7 primeiro, por ser o que já existia antes deste ecrã. A ordem
/// cronológica explica-se sozinha e põe o 1.4.4, que ainda não lançou, entre
/// os vizinhos em vez de pendurado no fim.
///
/// **O custo é no telemóvel e foi medido**: ali as portas empilham-se, uma
/// por ecrã, portanto quem usa o 1.8.7 — 60% do mercado, 1.982 personagens
/// contra 1.317 — desliza dois cards para lá chegar. Encurtá-los não serve:
/// três num ecrã de 844 px dariam 233 px de altura cada, que é a faixa larga
/// já rejeitada, e a arte das classes tem a cara a um quinto do topo.
///
/// A version [versoes] has no row for — missing from the file entirely, or
/// the file itself never written yet — still gets a door here, with
/// [Porta.resumo] left `null`. That is deliberate: "nobody has collected
/// this version" and "nobody has collected anything at all" are the same
/// fact from a single door's point of view, and both draw the same way.
List<Porta> portasDe(Map<String, VersaoResumo> versoes) => [
  Porta(
    chave: IndexRepository.pw126,
    nome: rotas.pw126,
    rota: '/${rotas.pw126}',
    descricao:
        'O mais antigo, online há mais de cinco anos. Três raças, as seis '
        'classes iniciais e rates baixas — o PW clássico.',
    resumo: versoes[IndexRepository.pw126],
  ),
  // **Sem rota e sem índice: a porta existe para dizer que vem aí.** A chave
  // não está em `IndexRepository` de propósito — aquela classe mapeia chave
  // para ficheiro e recusa o que não conhece, portanto pô-la lá prometeria um
  // `market_index_144.json` que não existe. No dia em que existir, a chave
  // muda de sítio, a rota nasce, e esta porta acende sozinha.
  Porta(
    chave: chavePw144,
    nome: '1.4.4',
    rota: null,
    // **Esta frase tem data de validade: 13/11/2026.** A partir do dia em que
    // o servidor abrir, *abre a 13 de novembro* deixa de ser notícia e passa a
    // ser história — e o mesmo dia em que a rota nasce é o dia de a reescrever.
    // Fica dito aqui porque é onde quem ligar a porta vai passar.
    descricao:
        'Abre a 13 de novembro de 2026. Cinco raças, dez classes, meta '
        'nirvana e rates baixas.',
    // Lê o resumo na mesma, e isso não é zelo inútil: a porta fica a saber o
    // que foi colhido e recusa abrir **por falta de rota**, que é a verdade.
    // Ignorar a linha faria `pronta` ser falsa por acidente em vez de por
    // razão, e no dia em que o 1.4.4 lançar alguém teria de se lembrar de
    // ligar duas coisas em vez de uma.
    resumo: versoes[chavePw144],
  ),
  Porta(
    chave: IndexRepository.pw187,
    nome: rotas.pw187,
    rota: '/${rotas.pw187}',
    descricao:
        'Aberto em junho de 2026, o mais atualizado. Rate média, conteúdos '
        'novos e todas as classes e instâncias.',
    resumo: versoes[IndexRepository.pw187],
  ),
];

/// O 1.4.4, que ainda não lançou.
///
/// Declarada aqui e não em `IndexRepository` porque não há ficheiro nenhum
/// para ler — ver a porta acima.
const chavePw144 = 'pw144';
