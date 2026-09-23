import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/canal_ao_vivo.dart';
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

/// The streamer's own art, holding the left of the card and dying into it.
///
/// A quarter of the width and no more: the card is a line of facts and the
/// picture is a signature on it. It fades rather than ending at an edge,
/// because a hard border would make the card read as two cards.
///
/// **A channel with no file gets nothing at all**, quietly — the same
/// fallback an item icon makes, and the reason a streamer who has sent no art
/// is not made to look like a streamer whose art failed to load.
class _Arte extends StatelessWidget {
  const _Arte({required this.login, required this.aoCarregar});

  final String login;

  /// Called the first time a frame of the picture is ready. It is how the card
  /// learns there is art at all, since a 404 is only known on arrival.
  final VoidCallback aoCarregar;

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
              frameBuilder: (_, child, frame, _) {
                if (frame != null) aoCarregar();
                return child;
              },
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x0013132A),
                    Color(0x8013132A),
                    PWColors.surface,
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ],
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
  /// and right-aligning their facts would leave half a card empty beside
  /// nothing. So the card stays what it always was until a picture actually
  /// arrives — a streamer who sent none is never made to look like one whose
  /// art failed to load.
  bool _temArte = false;

  CanalAoVivo get canal => widget.canal;

  /// Wide **and** carrying art. Everything that moves the facts to the right
  /// asks this; everything about spacing asks `widget.wide`.
  bool get wide => widget.wide && _temArte;

  @override
  Widget build(BuildContext context) => Material(
    color: PWColors.surface,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => unawaited(
        launchUrl(Uri.parse(canal.url), mode: LaunchMode.externalApplication),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PWColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _Arte(
              login: canal.canal,
              aoCarregar: () {
                if (_temArte) return;
                // After the frame: the image reports while the tree is being
                // built, and setState during build is an error.
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
  );

  /// Wide, the facts sit **against the right edge**, with the art holding the
  /// left. Narrow, they follow the art, because right-aligning on a 350 px
  /// card walks `ao vivo na Twitch` straight over the picture — measured, not
  /// guessed.
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
          SizedBox(width: limites.maxWidth * _larguraDaArte + (wide ? 0 : 12)),
        if (wide) const Spacer(),
        Flexible(child: _fatos()),
      ],
    ),
  );

  /// The dot rides on the **name's** line, not beside the block: with the
  /// lines ragged on the left, a dot outside would sit against whichever line
  /// happens to be longer, which is the one that is not the name.
  Widget _fatos() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: wide
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The dot carries the whole "now": green is the signal everybody
          // already knows, and it is the only green on the page.
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: PWColors.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              canal.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PWColors.text,
                fontSize: wide ? 19 : 17,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        _abaixo(canal),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: wide ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: PWColors.textMuted,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ],
  );

  /// What is under the name: the game and the audience, when they are known.
  ///
  /// The title of the stream is deliberately left out. It is written for the
  /// Twitch page — full of emoji, coupons and `!commands` — and pasted here it
  /// reads as spam on somebody else's site.
  ///
  /// **On a phone it loses `ao vivo na Twitch`.** With art holding a quarter
  /// of a 350 px card the line ellipsized, and what it ate was `39
  /// assistindo` — the one part that differs between two streamers. The green
  /// dot and the heading already say live, so the phrase was the piece that
  /// could go.
  String _abaixo(CanalAoVivo canal) {
    final partes = <String>[
      if (widget.wide) 'ao vivo na Twitch',
      if (canal.jogo != null && canal.jogo!.isNotEmpty) canal.jogo!,
      if (canal.espectadores != null)
        canal.espectadores == 1
            ? '1 assistindo'
            : '${canal.espectadores} assistindo',
    ];
    return partes.join('  ·  ');
  }
}
