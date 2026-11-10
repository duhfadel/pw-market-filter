import 'video.dart';

/// Uma guerra, e não um vídeo: as gravações de uma mesma batalha, juntas.
///
/// **Quatro pessoas gravaram a `Ragnarok x BUDOKAI` de 01/11/2026** — Mozaum,
/// ANTIФak, kS e COMECU, cada um na sua classe. São quatro linhas na tabela
/// `videos` e **uma** guerra, e uma lista que as imprimisse separadas daria
/// quatro linhas idênticas seguidas, que se lê como defeito e não como
/// cobertura. Medido na base a 10/11/2026: dos 47 vídeos visíveis, é o caso
/// mais comum.
///
/// É a mesma leitura que os ovos de mascote forçaram — duas coisas que
/// parecem iguais lado a lado prometem uma diferença que não existe — vista
/// do outro lado: aqui a diferença existe (são ângulos diferentes) e o que
/// não pode repetir-se é a *manchete*.
class GuerraRecente {
  const GuerraRecente({required this.gravacoes});

  /// As gravações desta guerra, na ordem em que chegaram.
  ///
  /// Nunca vazia: uma guerra é construída a partir de pelo menos um vídeo.
  final List<Video> gravacoes;

  Video get primeira => gravacoes.first;

  /// `Ragnarok x BUDOKAI` — o que a guerra é.
  String? get manchete => primeira.manchete;

  DateTime? get data => primeira.data;
  String? get dataEscrita => primeira.dataEscrita;

  /// Quem gravou, e **a classe só aparece quando há uma pessoa só**.
  ///
  /// Com uma: `TeamSpeakUser · Arqueiro`, que é o que a tela de Guerras já
  /// imprime. Com quatro, as classes somam quatro pares nome-classe numa
  /// linha que ninguém lê — e a classe deixa de ser informação sobre a
  /// guerra para ser ruído sobre quem a filmou. `Mozaum, ANTIФak, kS e
  /// COMECU` diz o que interessa: que há quatro ângulos.
  String? get quem {
    final nomes = [for (final v in gravacoes) ?v.personagem];
    if (nomes.isEmpty) return null;
    if (nomes.length == 1) {
      final classe = primeira.classe;
      return classe == null ? nomes.single : '${nomes.single} · $classe';
    }
    // `a, b e c` — a vírgula da enumeração e o «e» antes do último, como se
    // escreve em português. Um `join(', ')` daria `a, b, c`, que lê como
    // lista truncada.
    return '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
  }

  /// Quantos ângulos — para a linha poder dizer que há mais de um.
  int get angulos => gravacoes.length;
}

/// Agrupa [videos] por guerra, da mais recente para a mais antiga.
///
/// **A chave é a manchete mais o dia**, e precisa das duas. Só a manchete
/// junta duas `Ragnarok x BUDOKAI` travadas em semanas diferentes, que são
/// guerras diferentes; só o dia junta guerras distintas do mesmo sábado, e a
/// guerra territorial é semanal, portanto esse caso é a norma e não a
/// excepção.
///
/// Um vídeo sem manchete nenhuma não se junta a ninguém: sem nome, duas
/// gravações do mesmo dia podiam ser de qualquer coisa, e juntá-las seria
/// afirmar uma guerra que ninguém nomeou.
List<GuerraRecente> guerrasRecentes(List<Video> videos) {
  final porGuerra = <String, List<Video>>{};
  final soltos = <Video>[];

  for (final video in videos) {
    final manchete = video.manchete;
    if (manchete == null) {
      soltos.add(video);
      continue;
    }
    porGuerra.putIfAbsent('$manchete|${video.data}', () => []).add(video);
  }

  final guerras = [
    for (final gravacoes in porGuerra.values)
      GuerraRecente(gravacoes: gravacoes),
    for (final video in soltos) GuerraRecente(gravacoes: [video]),
  ];

  // **Sem data vai para o fim, nunca para o topo.** `null` ordenado como se
  // fosse antigo poria uma guerra sem dia a abrir a lista do que é recente,
  // que é precisamente a afirmação que ela não tem como sustentar.
  guerras.sort((a, b) {
    final da = a.data;
    final db = b.data;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });
  return guerras;
}
