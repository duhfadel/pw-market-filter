/// A community channel, and whether it was streaming when the Worker looked.
///
/// The browser cannot ask Twitch this — the API needs a secret, and a secret
/// compiled into the site is not a secret. So the Cloudflare Worker asks every
/// five minutes and writes the answer to Supabase; this is that row.
class CanalAoVivo {
  const CanalAoVivo({
    required this.canal,
    required this.nome,
    required this.aoVivo,
    required this.titulo,
    required this.jogo,
    required this.espectadores,
    required this.vistoEm,
  });

  /// The login, which is what the address uses: `twitch.tv/<canal>`.
  final String canal;

  /// How the streamer writes their own name. `PersyBR` is theirs; `persybr`
  /// is the address.
  final String nome;

  final bool aoVivo;
  final String? titulo;
  final String? jogo;

  /// `null` means not recorded, which is not the same as nobody watching.
  final int? espectadores;

  /// When the Worker last looked.
  final DateTime? vistoEm;

  factory CanalAoVivo.fromJson(Map<String, dynamic> json) {
    final canal = (json['canal'] as String?) ?? '';
    final nome = (json['nome'] as String?) ?? '';

    return CanalAoVivo(
      canal: canal,
      // Falls back to the login rather than to nothing: the display name only
      // arrives after the first successful check, and "está ao vivo" with no
      // name in front of it is a sentence about nobody.
      nome: nome.isEmpty ? canal : nome,
      aoVivo: json['ao_vivo'] == true,
      titulo: json['titulo'] as String?,
      jogo: json['jogo'] as String?,
      espectadores: (json['espectadores'] as num?)?.toInt(),
      vistoEm: DateTime.tryParse((json['visto_em'] as String?) ?? ''),
    );
  }

  String get url => 'https://www.twitch.tv/$canal';
}

/// The words that say a stream is about this game.
///
/// Matched against the Twitch **category** and the **title**, because the two
/// fail in opposite directions and either one alone would be wrong. A
/// streamer who sets the category correctly may title the stream anything;
/// one who leaves the category on *Just Chatting* usually still writes the
/// game in the title. Requiring both would hide most real streams; requiring
/// neither is the status quo this rule exists to end.
///
/// **`PW` is deliberately not here.** Two letters match far too much — a
/// nickname, a guild tag, a word like *pwzinho* — and a strip that shows
/// somebody playing something else is exactly the wrong answer this rule was
/// added to prevent. The cost is a stream titled only `PW` going unshown,
/// which is visible to its owner and fixable by typing two words.
const _marcasDoJogo = ['perfect world'];

/// Whether [canal] is streaming this game rather than something else.
///
/// A channel that is live with no category and no title says nothing, and
/// nothing is not a yes: it is treated as *not this game*. Announcing a
/// stream that turns out to be another game costs the same trust as
/// announcing one that already ended.
bool jogandoOJogo(CanalAoVivo canal) {
  final onde = '${canal.jogo ?? ''} ${canal.titulo ?? ''}'.toLowerCase();
  return _marcasDoJogo.any(onde.contains);
}

/// As versões que o site serve, e as duas grafias de cada uma.
///
/// **A versão vem do título da transmissão e não de uma coluna**, ideia do
/// dono e melhor do que a alternativa: a Twitch só diz *Perfect World* e não
/// distingue versão, e o título é reescrito a cada transmissão — portanto quem
/// muda de versão muda sozinho. Uma coluna envelheceria em silêncio, e o site
/// só mostra quem está **ao vivo**, logo o título existe exactamente quando é
/// preciso.
/// A forma com pontos é a chave; a nua é o mesmo número sem eles.
const _grafiasDaVersao = {'1.8.7': '187', '1.2.6': '126', '1.4.4': '144'};

/// Que versão o título de [titulo] diz, ou `null` quando não diz uma só.
///
/// **Falsos positivos são o único dano real**, e é isso que ordena as
/// decisões aqui: não mostrar alguém custa visibilidade, mostrá-lo na versão
/// errada é o site a afirmar o que não sabe.
///
/// **A fronteira é o dígito e o ponto, nunca `\b`.** `PW187` é a grafia mais
/// comum de todas e entre o `W` e o `1` não há fronteira de palavra nenhuma,
/// portanto um `\b187\b` perderia justamente o caso que mais aparece. O que
/// tem de ser recusado é o número dentro de outro número — `2187`, `1870`,
/// `187.5` — e é isso que a vizinhança de dígitos e pontos exclui.
///
/// **A forma nua recusa também a letra depois, e a com pontos não.** `187k`
/// é dano ou ouro, não uma versão, e títulos destes estão cheios de números
/// com `k`; `1.8.7` não tem como ser outra coisa. A assimetria é deliberada:
/// letra **antes** é como se escreve o jogo (`pw187`), letra **depois** é
/// uma unidade. O preço é perder um `PW187BR`, que ninguém escreveu ainda.
///
/// **Duas versões nomeadas contam como não saber.** Decisão minha e barata de
/// mudar: quem escreve as duas não disse em qual está, e escolher pela ordem
/// de aparição seria o site a inventar a resposta.
///
/// O título é lido e **nunca mostrado** — está cheio de cupões e emoji, e já
/// tinha sido deixado de fora do cartão por isso.
String? versaoDaTransmissao(String? titulo) {
  if (titulo == null || titulo.isEmpty) return null;

  final achadas = <String>{};
  for (final entrada in _grafiasDaVersao.entries) {
    final comPontos = RegExp(
      '(?<![0-9.])${RegExp.escape(entrada.key)}(?![0-9.])',
    );
    final nua = RegExp('(?<![0-9.])${entrada.value}(?![\\w.])');
    if (comPontos.hasMatch(titulo) || nua.hasMatch(titulo)) {
      achadas.add(entrada.key);
    }
  }

  return achadas.length == 1 ? achadas.first : null;
}

/// How old a reading may be before it stops meaning anything.
///
/// The Worker looks every five minutes, so twelve is three missed rounds —
/// wide enough to survive a blip, narrow enough that nothing on screen is ever
/// badly out of date.
const janelaDoAoVivo = Duration(minutes: 12);

/// Who is live right now, busiest first.
///
/// **Stale is not live**, and that is the whole reason this function exists
/// rather than a `where(aoVivo)`. The day the Worker dies — token expired,
/// cron switched off — the last rows keep saying "live" for as long as nobody
/// notices, and the site would announce a stream that ended on Tuesday. One
/// wrong badge costs more than the strip earns: somebody who clicks and finds
/// an offline channel stops believing the next one.
///
/// Busiest first so a quiet channel is not permanently the face of the site
/// just for being first in the table.
///
/// **Playing something else is not live either**, for the same reason stale is
/// not live: the card promises a Perfect World stream, and a reader who clicks
/// into a different game stops believing the next card. See [jogandoOJogo].
List<CanalAoVivo> aoVivoAgora(List<CanalAoVivo> canais, DateTime agora) {
  final vivos = [
    for (final canal in canais)
      if (canal.aoVivo &&
          canal.vistoEm != null &&
          agora.difference(canal.vistoEm!) < janelaDoAoVivo &&
          // Live, fresh, and **playing this game**. A channel from this
          // community streaming something else is still somebody's channel —
          // it is just not news for a Perfect World site, and putting it in
          // the strip spends the reader's trust on a click they did not want.
          jogandoOJogo(canal))
        canal,
  ];

  vivos.sort((a, b) => (b.espectadores ?? 0).compareTo(a.espectadores ?? 0));
  return vivos;
}

/// Se [canal] pertence à página de [versao] — pedido do dono: no 1.8.7 só
/// quem joga 1.8.7, e assim por diante.
///
/// **[versao] nula é a raiz**, que não é de versão nenhuma e por isso não
/// afirma nada ao mostrar quem não escreveu a sua. Com versão, quem não a
/// nomeia no título fica de fora — decisão do dono. O custo é visível a quem
/// transmite e resolve-se escrevendo duas palavras no título.
///
/// **Separada de [aoVivoAgora] de propósito.** Aquela responde *está ao vivo
/// neste jogo*, que é um facto sobre o canal e o mesmo em todas as telas, e é
/// por isso que o cubit — único para o site inteiro — a aplica uma vez. Esta
/// responde *pertence a esta tela*, que muda de tela para tela e por isso é
/// decidida onde a tela sabe quem é.
bool transmiteAVersao(CanalAoVivo canal, String? versao) =>
    versao == null || versaoDaTransmissao(canal.titulo) == versao;
