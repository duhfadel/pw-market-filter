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
