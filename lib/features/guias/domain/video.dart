/// Um vídeo de uma das telas de guia.
///
/// **O id do YouTube e não o endereço**, porque dele derivam as três coisas
/// que a tela precisa — a miniatura, o link e um dia o incrustável — e guardar
/// o endereço convidaria `youtube.com/watch`, `youtu.be` e `/embed` a
/// conviverem na mesma coluna, com a tela a ter de adivinhar qual é qual.
class Video {
  const Video({
    required this.secao,
    required this.youtube,
    this.titulo,
    this.classe,
    this.personagem,
    this.data,
    this.detalhes,
    this.ordem = 0,
  });

  /// Qual tela o mostra: `guerras`, `astrolabio`, `titulos`, `passivas`,
  /// `multicontas`. Texto livre de propósito — uma seção nova não pode custar
  /// uma migração.
  final String secao;

  final String youtube;

  /// O nome do vídeo, ou nulo quando ele não acrescenta nada.
  ///
  /// **Opcional por medição e não por gosto.** Posto o primeiro vídeo de
  /// guerra, o título que o YouTube dá — `Fluxo x Kaizen 20/09/2026 -
  /// Mozaum` — repetia exactamente os três campos que o card já imprime por
  /// baixo dele, e o card dizia as mesmas coisas duas vezes. Nas Guerras os
  /// campos *são* o título; nas outras quatro seções, que não têm classe nem
  /// personagem nem guerra, o título é a única coisa que o card tem para
  /// dizer.
  ///
  /// Daí ser opcional em vez de uma regra por seção escondida no widget:
  /// quem escreve a linha decide, no painel, onde o trabalho acontece.
  final String? titulo;

  /// O que o card põe em manchete: o título, ou os detalhes quando não há
  /// título. Nulo quando não há nem um nem outro.
  ///
  /// A promoção é o que impede o card sem título de abrir com a linha
  /// esmaecida de quem-e-quando: `Fluxo x Kaizen` é a manchete certa de um
  /// vídeo de guerra, e é o que sobra para a dar.
  String? get manchete => titulo ?? detalhes;

  /// Os detalhes, quando não foram já gastos na manchete — para o card não
  /// os imprimir duas vezes.
  String? get detalhesPorBaixo => titulo == null ? null : detalhes;

  /// A classe de quem grava, e só as Guerras Territoriais a usam. Nula nas
  /// outras seções, onde o filtro por classe não desenha.
  final String? classe;

  /// Quem gravou, pelo nick do personagem — que é como esta comunidade
  /// identifica alguém. Nulo onde não se sabe: inventar um crédito é pior do
  /// que não dar nenhum.
  final String? personagem;

  /// O dia da guerra. Nulo nas seções que não são guerras.
  final DateTime? data;

  /// A linha livre por baixo do nome e da data — `Guerra Alpha x Omega`, ou o
  /// que a ocasião pedir.
  ///
  /// **Um campo e não duas colunas de guilda**, por decisão do dono. Num
  /// painel editado à mão cada campo a mais é um campo que fica por
  /// preencher, e as outras seções não teriam duas guildas para dar.
  final String? detalhes;

  /// `12/10/2026`, ou nulo. Nunca o formato ISO que a base guarda: ninguém
  /// lê `2026-10-12` como uma data desta semana.
  String? get dataEscrita => data == null
      ? null
      : '${data!.day.toString().padLeft(2, '0')}/'
            '${data!.month.toString().padLeft(2, '0')}/${data!.year}';

  final int ordem;

  /// A miniatura, derivada do id.
  ///
  /// `hqdefault` e não `maxresdefault`: a segunda só existe se o canal tiver
  /// enviado uma capa em alta, e quando não existe o YouTube responde uma
  /// imagem cinzenta de 120×90 em vez de um 404 — ou seja, falha parecendo
  /// que funcionou, que é a pior forma. A `hqdefault` existe sempre.
  String get miniatura => 'https://img.youtube.com/vi/$youtube/hqdefault.jpg';

  String get endereco => 'https://www.youtube.com/watch?v=$youtube';

  /// Se [procura] aparece em alguma coisa que este vídeo diz.
  ///
  /// Em tudo — título, personagem, detalhes e classe — e não só num campo.
  /// É isso que torna a guilda procurável sem lhe dar coluna própria: ela
  /// está escrita em `detalhes` e aqui é tratada como qualquer outra palavra.
  bool contem(String procura) {
    final alvo = procura.trim().toLowerCase();
    if (alvo.isEmpty) return true;
    return [
      ?titulo,
      ?personagem,
      ?detalhes,
      ?classe,
    ].join(' ').toLowerCase().contains(alvo);
  }

  factory Video.fromJson(Map<String, dynamic> json) => Video(
    secao: json['secao'] as String? ?? '',
    youtube: json['youtube'] as String? ?? '',
    titulo: _texto(json['titulo']),
    classe: _texto(json['classe']),
    personagem: _texto(json['personagem']),
    data: DateTime.tryParse(json['data'] as String? ?? ''),
    detalhes: _texto(json['detalhes']),
    ordem: json['ordem'] as int? ?? 0,
  );
}

/// Um campo de texto do painel, ou nulo quando está em branco.
///
/// Branco é "não se aplica" e tem de virar nulo: uma string vazia desenharia
/// um chip sem nome na fila do filtro e um separador solto no card.
String? _texto(Object? valor) {
  final texto = (valor as String?)?.trim();
  return texto == null || texto.isEmpty ? null : texto;
}

/// As classes que os vídeos de [videos] realmente trazem, pela ordem em que
/// aparecem.
///
/// **Lido dos vídeos e nunca da lista das dezassete classes do jogo**, que é a
/// regra que todo controlo deste site segue: uma fila de dezassete ícones dos
/// quais quinze não dão resultado ensina o contrário do que devia.
List<String> classesCom(List<Video> videos) {
  final vistas = <String>[];
  for (final video in videos) {
    final classe = video.classe;
    if (classe != null && !vistas.contains(classe)) vistas.add(classe);
  }
  return vistas;
}
