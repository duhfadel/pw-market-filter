import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/canal_ao_vivo.dart';
import '../../domain/streamer_accent.dart';
import '../ao_vivo_view_model.dart';

/// Who from the community is streaming, in a card of its own.
///
/// It started as one grey line tucked above the tools and that was a mistake
/// worth recording: asked for *discreet*, it came out **invisible** — the
/// owner opened the page and could not find it. Discreet means not shouting;
/// invisible means not doing the job. If nobody notices, the streamer gains
/// nothing, and helping them was the entire point.
///
/// So it has a heading and a frame now, like the tools do, and still no
/// thumbnail and no animation beyond a slow swap: this is a courtesy, nobody
/// paid for it, and it must not read as bought placement.
///
/// **It disappears entirely when nobody is live.** A card saying "ninguém
/// online" spends a whole frame to deliver a non-event.
/// Where a streamer's own art lives, addressed by their login.
///
/// **Nothing records the file name, because the login already does.** A column
/// holding `gsafoot.webp` beside a file called `gsafoot.webp` is one fact
/// written twice, and the two drift the day somebody renames one — so the
/// address is derived, the way an item icon is derived from its id.
///
/// It is a Supabase bucket rather than `assets/`, and that is the difference
/// between a streamer sending art and the art being on the page. The guild
/// crests went the other way for the opposite reason: a guild is born rarely,
/// and its art is chosen by us. Here somebody else sends it, and waiting on a
/// deploy would put us in the middle of a courtesy.
///
/// The bucket refuses anything over 512 KB and anything that is not an image,
/// which is the guard that matters: the first file offered was 4.87 MB, and in
/// a repository it would have been resized before anyone noticed.
/// How much of the card the art holds.
const _larguraDaArte = 0.24;

/// The card's height on wide — fixed, rather than following its content.
///
/// The redesign's whole point is a card that fills its width with a scoreboard
/// at one end and a name at the other, and a height that wandered with the
/// text would make the strip jump every seven seconds as it cycles between a
/// streamer with a game name and one without. On narrow there is no fixed
/// height: a phone has no neighbouring card to jump against, and the art
/// column still needs to fill whatever height the facts settle on.
const _alturaCard = 164.0;

String arteDoStreamer(String login) =>
    'https://yadfbwsolmkcaylbxviw.supabase.co'
    '/storage/v1/object/public/streamers/${login.toLowerCase()}.webp';

class AoVivoStrip extends StatefulWidget {
  const AoVivoStrip({required this.wide, super.key});

  final bool wide;

  @override
  State<AoVivoStrip> createState() => _AoVivoStripState();
}

class _AoVivoStripState extends State<AoVivoStrip> {
  int _atual = 0;
  Timer? _relogio;

  /// Slow on purpose: fast enough that a second streamer is seen, slow enough
  /// that the card is not moving while somebody reads it.
  static const _troca = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _relogio = Timer.periodic(_troca, (_) {
      if (mounted) setState(() => _atual++);
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AoVivoViewModel, List<CanalAoVivo>>(
        builder: (context, canais) {
          if (canais.isEmpty) return const SizedBox.shrink();

          final canal = canais[_atual % canais.length];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Titulo(quantos: canais.length),
              SizedBox(height: widget.wide ? 12 : 10),
              // Fades between streamers instead of cutting: a hard swap reads
              // as a glitch on a card this quiet.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: CardDoStreamer(
                  key: ValueKey(canal.canal),
                  canal: canal,
                  wide: widget.wide,
                ),
              ),
              SizedBox(height: widget.wide ? 26 : 20),
            ],
          );
        },
      );
}

/// The streamer's own art, as the sharp emblem holding its own column.
///
/// **Only ever mounted after [_SondaDeArte] has confirmed a picture
/// actually decodes.** It used to be mounted unconditionally and fail
/// silently through its own `errorBuilder` — which sounds like the same
/// "draws nothing" rule every other missing-art case in this app follows,
/// and was not: the `errorBuilder`'s `SizedBox.shrink()` sat inside a
/// `Stack(fit: StackFit.expand)`, which forces every non-positioned child
/// to the parent's full size regardless of what it asked for. "Nothing"
/// came out as an empty rectangle at the column's full size, painted over
/// by the gradient below, with a hard seam at [_larguraDaArte] where that
/// gradient ended — exactly what zMaroto's card showed: two shades of
/// violet and a line, not the absence the rest of the app promises. Moving
/// the yes/no decision in front of this widget, rather than inside it, is
/// the fix: there is no card-shaped rectangle to see until there is a
/// picture to put in it.
///
/// A quarter of the width and no more, filling the card's full height — the
/// art is a 690×231 banner whose emblem sits in its left 170 px, so cropping
/// to [_larguraDaArte] lands exactly on it. The right edge fades into the
/// panel rather than ending on a hard line, so the column reads as part of
/// the card rather than a second one stitched on.
class _Emblema extends StatelessWidget {
  const _Emblema({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _larguraDaArte,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              arteDoStreamer(login),
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              // Defensive rather than expected: [_SondaDeArte] already
              // proved a frame decodes for this exact URL, and the engine's
              // image cache means this request is normally answered from
              // memory, not the network, before a frame is even painted.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    PWColors.surface.withValues(alpha: 0.08),
                    PWColors.surface.withValues(alpha: 0.5),
                    PWColors.surface,
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Learns whether this streamer has art at all — with **zero footprint**:
/// it paints nothing and reserves no space while it waits for an answer.
/// `SizedBox.shrink` wrapping the image is enough on its own, because this
/// widget sits directly in the outer `Stack`, which lays out loose
/// (`StackFit.loose`, the default) rather than forcing children to fill —
/// unlike the trap documented on [_Emblema].
///
/// [_Emblema] takes over, mounted for the first time, the moment
/// [aoConfirmar] fires.
class _SondaDeArte extends StatelessWidget {
  const _SondaDeArte({required this.login, required this.aoConfirmar});

  final String login;

  /// Called the first time a frame of the picture is ready. It is how the
  /// card learns there is art at all, since a 404 is only known on arrival.
  final VoidCallback aoConfirmar;

  @override
  Widget build(BuildContext context) => SizedBox.shrink(
    child: Image.network(
      arteDoStreamer(login),
      frameBuilder: (_, child, frame, _) {
        if (frame != null) aoConfirmar();
        return child;
      },
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// The same art again, behind everything, as scenery rather than a signature.
///
/// Anchored to the far side of the card — the opposite end from [_Emblema] —
/// so the two copies do not sit on top of each other: one is the sharp
/// portrait, the other is ambience filling the empty right half.
///
/// The scrim sits on top of it rather than under: without one, the texture
/// at full width would fight the scoreboard that lands over its right edge,
/// which is exactly where the darkening has to be.
///
/// Degrades the same way [_Emblema] does — a missing file draws nothing, not
/// a broken box.
class _FundoTextura extends StatelessWidget {
  const _FundoTextura({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.42,
          child: Image.network(
            arteDoStreamer(login),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                PWColors.surface.withValues(alpha: 0),
                PWColors.surface.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The accent as a diagonal wash, entering from the emblem's corner.
///
/// The same idea as the weapon-tier tint on a result card: a gradient rather
/// than a flat fill, so it reads at a glance without becoming a second block
/// of colour to parse.
///
/// **It dies before the number on purpose.** The viewer count is the one
/// datum on this card that changes minute to minute, and it is the thing a
/// returning reader actually comes back to check — the colour must never
/// compete with it.
class _Lavagem extends StatelessWidget {
  const _Lavagem({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: [accent.withValues(alpha: 0.38), accent.withValues(alpha: 0)],
          stops: const [0, 0.5],
        ),
      ),
    ),
  );
}

/// The rule above the card, matching the tools' headings.
class _Titulo extends StatelessWidget {
  const _Titulo({required this.quantos});

  final int quantos;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        'STREAMERS AMIGOS',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      // The count only when it says something: "1 ao vivo" beside one card is
      // the card repeating itself.
      if (quantos > 1) ...[
        Text(
          '$quantos ao vivo',
          style: const TextStyle(color: PWColors.live, fontSize: 11),
        ),
        const SizedBox(width: 12),
      ],
      const Expanded(child: Divider(color: PWColors.border, height: 1)),
    ],
  );
}

class CardDoStreamer extends StatefulWidget {
  const CardDoStreamer({required this.canal, required this.wide, super.key});

  final CanalAoVivo canal;
  final bool wide;

  @override
  State<CardDoStreamer> createState() => _CardDoStreamerState();
}

class _CardDoStreamerState extends State<CardDoStreamer> {
  /// **Starts false, and that is the point.** Most channels have sent no art,
  /// and reserving a column for one would leave a gap beside nothing. So the
  /// facts stay full-width until a picture actually arrives — a streamer who
  /// sent none is never made to look like one whose art failed to load.
  bool _temArte = false;

  CanalAoVivo get canal => widget.canal;

  /// Every layer that wears a colour reads this one getter, so the card and
  /// the streamer never disagree about which colour that is.
  Color get _accent => StreamerAccent.of(canal.canal);

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Container(
      // The glow lives on this outer box, unclipped. The inner one below
      // clips its own border radius for the art and the wash; clipping here
      // too would cut the blur off at the same rounded rect it is supposed to
      // sit outside of.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => unawaited(
            launchUrl(
              Uri.parse(canal.url),
              mode: LaunchMode.externalApplication,
            ),
          ),
          child: Container(
            height: widget.wide ? _alturaCard : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              // Centred rather than the default top-left: on wide the card
              // is a fixed [_alturaCard] and the facts are usually shorter
              // than that, so top-left would leave them pinned to the top
              // with dead air below. On narrow the stack has no height to
              // spare beyond its content, so centring changes nothing there.
              alignment: Alignment.centerLeft,
              children: [
                _FundoTextura(login: canal.canal),
                _Lavagem(accent: accent),
                // No art, no column: see [_Emblema] and [_SondaDeArte] for
                // why this has to be a mount decision and not a fallback
                // drawn inside one widget that is always there.
                if (_temArte)
                  _Emblema(login: canal.canal)
                else
                  _SondaDeArte(
                    login: canal.canal,
                    aoConfirmar: () {
                      if (_temArte) return;
                      // After the frame: the image reports while the tree is
                      // being built, and setState during build is an error.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _temArte = true);
                      });
                    },
                  ),
                Padding(
                  padding: EdgeInsets.all(widget.wide ? 16 : 14),
                  child: _linha(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reserves the emblem's own width only once there is an emblem to clear —
  /// and only that: the facts no longer shift as a block towards the right,
  /// the way they did before the scoreboard existed. A name at the left and a
  /// number pinned at the right already anchor both ends of the card.
  ///
  /// Measured, not guessed. The art holds [_larguraDaArte] of the **card**,
  /// so the space the facts must clear is a fraction of the real width — an
  /// earlier version reserved fixed pixels and the name sat on the fade at
  /// 350 px while looking fine at 1400.
  Widget _linha() => LayoutBuilder(
    builder: (context, limites) => Row(
      children: [
        // Only when there is art. Reserving it anyway indented every
        // art-less card by a quarter and cut `7 assistindo` off the end of a
        // phone — space held for a picture that was never coming.
        if (_temArte)
          SizedBox(
            width: limites.maxWidth * _larguraDaArte + (widget.wide ? 0 : 12),
          ),
        Expanded(child: _fatos()),
      ],
    ),
  );

  /// The name and its live line on the left, the scoreboard on the right —
  /// the two ends the redesign exists to anchor.
  Widget _fatos() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: _nomeELinha()),
      if (canal.espectadores != null) ...[
        const SizedBox(width: 12),
        _Placar(espectadores: canal.espectadores!, wide: widget.wide),
      ],
    ],
  );

  /// The dot rides on the **name's** line, not beside the block: with the
  /// lines ragged on the left, a dot outside would sit against whichever line
  /// happens to be longer, which is the one that is not the name.
  Widget _nomeELinha() {
    final abaixo = _abaixo(canal);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The dot wears the streamer's own accent, the same as the
            // border, the glow and the wash — it is a slower rewrite than
            // those three, caught after the fact. The brief this card was
            // built from named three layers that carry the accent and never
            // mentioned the dot, so the pre-existing universal green rode
            // along unexamined rather than being chosen on purpose; the
            // approved design wanted it on-brand like everything else.
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                canal.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: PWColors.text,
                  fontSize: widget.wide ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        if (abaixo.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            abaixo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PWColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// What is under the name: the game, and that it is live, when they are
  /// known. The viewer count used to live here too; it is the scoreboard now.
  ///
  /// The title of the stream is deliberately left out. It is written for the
  /// Twitch page — full of emoji, coupons and `!commands` — and pasted here it
  /// reads as spam on somebody else's site.
  ///
  /// **On a phone it loses `ao vivo na Twitch`.** With art holding a quarter
  /// of a 350 px card the line used to ellipsize away `39 assistindo` — the
  /// one part that differed between two streamers. That number lives in the
  /// scoreboard now rather than in this line, but the phrase stays dropped on
  /// narrow regardless: the green dot and the heading above already say live,
  /// so it was never information, only room this line can still use for the
  /// game's name.
  String _abaixo(CanalAoVivo canal) {
    final partes = <String>[
      if (widget.wide) 'ao vivo na Twitch',
      if (canal.jogo != null && canal.jogo!.isNotEmpty) canal.jogo!,
    ];
    return partes.join('  ·  ');
  }
}

/// The viewer count, pinned to the card's far right.
///
/// **This is the fix for the defect the redesign exists to correct.** At
/// 1100 px wide, a name at the left and `58 assistindo` set at 13 px left
/// 800 px of nothing in the middle — the card read as unfinished rather than
/// quiet. A big number at the opposite end anchors the card the way the name
/// already anchors its own: the two things worth reading sit at the two ends
/// somebody's eye actually visits.
///
/// **Stays on the body face, never `PWTheme.display`.** There is no theming
/// mistake to make here since this widget never touches that constant, but
/// it is worth saying why out loud: Marcellus draws Roman numerals and its
/// `0` is barely an `O` — this number is read, not admired, and every number
/// on this site stays off the display face for that reason.
class _Placar extends StatelessWidget {
  const _Placar({required this.espectadores, required this.wide});

  final int espectadores;
  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '$espectadores',
        style: TextStyle(
          color: PWColors.text,
          fontSize: wide ? 38 : 26,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'ASSISTINDO',
        style: TextStyle(
          color: PWColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    ],
  );
}
