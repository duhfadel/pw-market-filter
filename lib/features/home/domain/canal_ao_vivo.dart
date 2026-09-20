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
List<CanalAoVivo> aoVivoAgora(List<CanalAoVivo> canais, DateTime agora) {
  final vivos = [
    for (final canal in canais)
      if (canal.aoVivo &&
          canal.vistoEm != null &&
          agora.difference(canal.vistoEm!) < janelaDoAoVivo)
        canal,
  ];

  vivos.sort((a, b) => (b.espectadores ?? 0).compareTo(a.espectadores ?? 0));
  return vivos;
}
