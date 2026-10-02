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
///
/// The banner's own pixel geometry — the one place these four numbers are
/// typed, so every crop and scale elsewhere in this file is a fraction of
/// them rather than a parallel guess.
const _larguraDoBanner = 690.0;
const _alturaDoBanner = 231.0;

/// The emblem's own width within the banner — everything from here to
/// [_larguraDoBanner] is the wall, the circuitry, the part that is
/// actually scenery.
const _larguraEmblemaNoBanner = 170.0;

/// The scenery's width within the banner: the banner minus the emblem.
const _larguraCenarioNoBanner = _larguraDoBanner - _larguraEmblemaNoBanner;

/// **The emblem's width is governed by the card's height, not by its
/// width, and this is why.** The banner is 690×231 — almost exactly 3:1
/// (690/231 ≈ 2.99) — so filling a box of height `H` with `BoxFit.cover`
/// scales the whole banner to about `3H` wide. The emblem itself is the
/// banner's left 170 px, which in that scaled picture comes out to
/// `170/231 ≈ 0.74` of `H`. That 0.74 is a property of the art file, not a
/// tuning knob, which is why it is a fraction of the two pixel measurements
/// above rather than a typed decimal.
const _proporcaoEmblemaPorAltura = _larguraEmblemaNoBanner / _alturaDoBanner;

/// The card's height on wide — fixed, rather than following its content.
///
/// The redesign's whole point is a card that fills its width with a scoreboard
/// at one end and a name at the other, and a height that wandered with the
/// text would make the strip jump every seven seconds as it cycles between a
/// streamer with a game name and one without. On narrow there is no fixed
/// height: a phone has no neighbouring card to jump against, and the art
/// column still needs to fill whatever height the facts settle on.
const _alturaCard = 132.0;

/// The emblem column's width on wide, in pixels — derived from
/// [_proporcaoEmblemaPorAltura] and [_alturaCard] rather than typed as a
/// second, independent number. If the card's height ever changes again,
/// this follows on its own instead of needing to be re-guessed: at 132 px
/// it comes to about 97 px, tight to the emblem instead of the 264 px a
/// flat 24%-of-width column used to reserve around a 121 px picture.
const _larguraEmblemaWide = _proporcaoEmblemaPorAltura * _alturaCard;

/// Narrow has no fixed height to feed the same formula — the card's height
/// there is whatever the name line, the line below it, the gap between
/// them and the padding come to, and that varies with whether a card has a
/// second line at all. This is an estimate of the common case (both lines
/// present), built from the same figures [_CardDoStreamerState] uses to lay
/// them out: 14 px of padding on each edge, a 17 px name at a 1.25 line
/// height, a 3 px gap, and a 13 px line below at a 1.4 line height. A
/// one-line card ends up a little shorter than this in reality, which
/// leaves its column a few spare pixels rather than cutting the emblem —
/// the safer side to be wrong on.
const _alturaEstreitaEstimada = 14 * 2 + 17 * 1.25 + 3 + 13 * 1.4;

/// The emblem column's width on narrow, by the same relationship as
/// [_larguraEmblemaWide].
const _larguraEmblemaEstreita =
    _proporcaoEmblemaPorAltura * _alturaEstreitaEstimada;

String arteDoStreamer(String login) =>
    'https://yadfbwsolmkcaylbxviw.supabase.co'
    '/storage/v1/object/public/streamers/${login.toLowerCase()}.webp';

class AoVivoStrip extends StatefulWidget {
  const AoVivoStrip({required this.wide, super.key});

  final bool wide;

  @override
  State<AoVivoStrip> createState() => _AoVivoStripState();
}

/// How many cards a page of the carousel holds.
///
/// Two on wide and one on narrow, and the number is measured rather than
/// chosen. A card's floor is its padding, the emblem's own column, the wider
/// of the name and the line under it, and the scoreboard — 441 px with the
/// line whole, 352 px once `ao vivo na Twitch` drops on narrow. At 1040 px of
/// page two cards come to 513 px each; three would be 337, under even the
/// short floor, so three can only fit by taking away the art column or the
/// number, which are the two things the redesign added on purpose.
int _porPagina(bool wide) => wide ? 2 : 1;

/// The streamers, two at a time, going round for ever.
///
/// **Infinite rather than a list with an end: after the last comes the
/// first.** `PageView.builder` with no `itemCount` is endless in both
/// directions, and the channel at each slot is its page's index modulo how
/// many are live — so a window of two always lands full, and the odd-number
/// case that would otherwise leave half a page empty never arises.
///
/// **Nothing moves while everyone already fits.** With two live on wide, or
/// one on narrow, there is no second page to go to: the timer is never armed,
/// the view does not scroll, and the section is exactly the static pair it
/// would have been without a carousel at all. Movement that changes nothing
/// is movement that costs attention for no answer.
///
/// **It stops under the pointer.** The one real defect of a carousel is the
/// card sliding out from under somebody on their way to clicking it — and
/// here that does not merely annoy, it opens the wrong streamer's channel.
/// This section exists to help the people who stream; sending a visitor to
/// the wrong one is worse than not rotating.
class _AoVivoStripState extends State<AoVivoStrip> {
  /// Where the carousel starts, far from zero so there is room to drag
  /// backwards: `PageView.builder` without an `itemCount` builds forwards for
  /// ever but nothing at a negative index, and a strip that cannot be dragged
  /// to the right reads as broken rather than as endless.
  ///
  /// **Everything else counts from here rather than from zero.** Taking the
  /// raw page number as the position would make the first page land wherever
  /// `10000 × slots` happens to fall in the list — with three live and two
  /// slots that is the third and the first, so the strip would open mid-list
  /// for no reason anybody could see.
  static const _paginaInicial = 10000;

  late final PageController _controlador = PageController(
    initialPage: _paginaInicial,
  );
  Timer? _relogio;
  bool _parado = false;

  /// Five seconds, on the owner's call, taken against a recommendation of
  /// seven and recorded as his.
  ///
  /// The argument for seven got **stronger** when the page went from one card
  /// to two, not weaker: a page now carries twice as much to read — two
  /// names, two games, two numbers — before anybody decides to click. What
  /// pulls the other way is that two a page also halves how many pages there
  /// are, so a full turn with four live is ten seconds at this rate against
  /// twenty-eight at the old one-card-every-seven.
  ///
  /// Five is the floor worth defending; below it the strip reads as blinking.
  static const _troca = Duration(seconds: 5);

  @override
  void dispose() {
    _relogio?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  /// Armed only once there is a page to go to, and re-armed on every build
  /// because the number of live channels changes under us: the Worker rewrites
  /// the table every five minutes, and a strip that was static with two live
  /// has to start moving when a third appears.
  void _acertarRelogio({required bool roda}) {
    if (!roda || _parado) {
      _relogio?.cancel();
      _relogio = null;
      return;
    }
    _relogio ??= Timer.periodic(_troca, (_) {
      if (!mounted || !_controlador.hasClients) return;
      _controlador.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _parar(bool parado) {
    if (_parado == parado) return;
    _parado = parado;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AoVivoViewModel, List<CanalAoVivo>>(
        builder: (context, canais) {
          if (canais.isEmpty) return const SizedBox.shrink();

          final porPagina = _porPagina(widget.wide);
          final roda = canais.length > porPagina;
          _acertarRelogio(roda: roda);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Titulo(quantos: canais.length),
              SizedBox(height: widget.wide ? 12 : 10),
              MouseRegion(
                onEnter: (_) => _parar(true),
                onExit: (_) => _parar(false),
                child: SizedBox(
                  height: _alturaDaFaixa(widget.wide),
                  child: roda
                      ? PageView.builder(
                          controller: _controlador,
                          itemBuilder: (_, pagina) => _pagina(
                            canais,
                            pagina - _paginaInicial,
                            porPagina,
                          ),
                        )
                      // No controller and no scrolling when it all fits: a
                      // `PageView` of one page still eats drag gestures, and a
                      // strip that moves a few pixels and springs back reads
                      // as a bug in a section that is otherwise still.
                      : _pagina(canais, 0, porPagina),
                ),
              ),
              SizedBox(height: widget.wide ? 26 : 20),
            ],
          );
        },
      );

  /// The channels on one page, wrapping round the end of the list.
  ///
  /// The modulo is what makes the window always land full — with three live
  /// and two slots, page 1 is the third and the first rather than the third
  /// and a hole. The only case that shows fewer is a market with fewer live
  /// than the page holds, where repeating somebody to fill the row would be
  /// the strip claiming more people are streaming than are.
  Widget _pagina(List<CanalAoVivo> canais, int pagina, int porPagina) {
    final quantos = porPagina < canais.length ? porPagina : canais.length;
    // Dart's `%` already returns a non-negative result for a positive right
    // operand, so dragging back past the opening page wraps round the end of
    // the list instead of reaching for a negative index.
    final cartoes = [
      for (var i = 0; i < quantos; i++)
        canais[(pagina * porPagina + i) % canais.length],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cartoes.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: CardDoStreamer(
              key: ValueKey('${cartoes[i].canal}-$pagina-$i'),
              canal: cartoes[i],
              wide: widget.wide,
            ),
          ),
        ],
      ],
    );
  }
}

/// A `PageView` has no height of its own, so the strip has to name one.
///
/// On wide that is the card's own fixed height — the same constant the card
/// lays itself out to, never a second guess at it. On narrow the card has no
/// fixed height, so this is [_alturaEstreitaEstimada] built from the very
/// figures the card uses, rounded up: a few spare pixels leave air under a
/// one-line card, where being short would clip the line that says how many
/// are watching.
double _alturaDaFaixa(bool wide) =>
    wide ? _alturaCard : _alturaEstreitaEstimada + 8;

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
/// by the gradient below, with a hard seam where that gradient ended —
/// exactly what zMaroto's card showed: two shades of violet and a line,
/// not the absence the rest of the app promises. Moving the yes/no decision
/// in front of this widget, rather than inside it, is the fix: there is no
/// card-shaped rectangle to see until there is a picture to put in it.
///
/// Sized by the card's height, not by its width — see
/// [_proporcaoEmblemaPorAltura] — filling the card's full height so the
/// crop lands on the banner's emblem rather than the blank space either
/// side of it. The right edge fades into the panel rather than ending on a
/// hard line, so the column reads as part of the card rather than a second
/// one stitched on.
class _Emblema extends StatelessWidget {
  const _Emblema({required this.login, required this.wide});

  final String login;
  final bool wide;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: wide ? _larguraEmblemaWide : _larguraEmblemaEstreita,
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
/// **Mounted only once [_CardDoStreamerState] has confirmed art exists —
/// the same guard [_Emblema] needs, and for the same reason.** This widget
/// carries the identical shape that caused the empty-column defect: an
/// `Image` whose `errorBuilder` returns `SizedBox.shrink()` inside a
/// `Stack(fit: StackFit.expand)`, which forces that empty box to the full
/// size of this layer regardless. It never actually showed a seam, but not
/// because the shape was safe — it was luck: the scrim gradient here has no
/// hard stop anywhere, so a forced-empty image under a smooth gradient that
/// spans the whole card looks the same as a present one. That stops being
/// true the moment somebody gives the gradient a hard edge tied to some
/// boundary, which is exactly how it broke on [_Emblema]. So it is gated
/// the same way instead of trusted to stay lucky: no art, no texture layer,
/// full stop.
///
/// **A second, separate bug lived here at 132 px: the texture showed the
/// emblem too, blown up to fill the whole card.** At that height the
/// banner (690×231) scales to only 396 px wide against a ~1100 px card, so
/// `BoxFit.cover` covers by *width* instead — scaling the banner to about
/// 2.1× and cropping it top and bottom, not left and right. Cropping
/// vertically leaves the full 690 px width on screen regardless of
/// `alignment`, because there is no horizontal slack left for an alignment
/// to place: `Alignment.centerRight` on a plain `Image` only matters when
/// the fit crops horizontally, and at this card's proportions it never
/// does. So the whole banner, emblem included, rendered across the card at
/// roughly twice its size.
///
/// **The fix has to remove the emblem from the source before `cover` ever
/// runs, not just ask `cover` to align away from it.** The `OverflowBox` /
/// `ClipRect` pair below renders the banner at its natural 690×231, then
/// clips it down to a virtual [_larguraCenarioNoBanner]×[_alturaDoBanner]
/// image holding only the scenery to the right of the emblem — the
/// `alignment: Alignment.centerRight` on the `OverflowBox` is what decides
/// *which* 520 px survive the clip, and it is the one property a test can
/// actually check (see `card_do_streamer_test.dart`; nothing in
/// `flutter_test` can see which pixels a crop keeps). Only then does the
/// outer `FittedBox` cover the real card with that already-emblem-free
/// image, so there is no scale or alignment left that could bring the
/// emblem back.
///
/// **Checked against the real art, not assumed: gsafoot's wall carries the
/// scale-up fine, persybr's does not.** persybr's scenery is sparse blue
/// circuit lines on near-black, and the same ~2× stretch that reads as
/// "concrete wall, slightly bigger" on gsafoot reads as "a few stray lines
/// and dots" on his — confirmed by rendering the actual crop at 1100×132.
/// Nothing here was forced to compensate: a texture that cannot carry the
/// width is a case for the colour wash to do more of the work on that
/// card, not for stretching the image further, and that is a follow-up,
/// not something this fix should paper over.
class _FundoTextura extends StatelessWidget {
  const _FundoTextura({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.42, child: CenarioDoBanner(login: login)),
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

/// The banner, cropped to its scenery — everything right of the emblem —
/// and scaled to cover whatever box it is given.
///
/// **Public, unlike almost everything else in this file, and for the same
/// reason [CardDoStreamer] is.** What this draws depends on which pixels a
/// crop keeps, which `flutter_test` cannot see even when an image loads —
/// the only thing a test can pin is the configuration that decides it
/// (`OverflowBox.alignment`, `FittedBox.alignment`), and that needs this
/// widget mounted on its own rather than buried behind
/// [_CardDoStreamerState]'s art-confirmed gate, which never opens in a test
/// harness with no network. See `card_do_streamer_test.dart`.
///
/// The crop itself: the banner renders at its full natural 690×231 inside
/// an [OverflowBox] that only reports [_larguraCenarioNoBanner] px wide,
/// right-aligned — so the 170 px that overflows to the *left* is the
/// emblem, and the [ClipRect] above cuts exactly that away before
/// [FittedBox] ever scales anything. `BoxFit.cover` on the untouched banner
/// cannot do this alone: at this card's proportions it always covers by
/// width, which leaves zero horizontal slack for any alignment to act on —
/// the full banner shows regardless of which way it points. Removing the
/// emblem from the source first is what makes alignment meaningful again.
class CenarioDoBanner extends StatelessWidget {
  const CenarioDoBanner({required this.login, super.key});

  final String login;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.cover,
    alignment: Alignment.centerRight,
    clipBehavior: Clip.hardEdge,
    child: ClipRect(
      child: SizedBox(
        width: _larguraCenarioNoBanner,
        height: _alturaDoBanner,
        child: OverflowBox(
          minWidth: _larguraDoBanner,
          maxWidth: _larguraDoBanner,
          minHeight: _alturaDoBanner,
          maxHeight: _alturaDoBanner,
          alignment: Alignment.centerRight,
          child: Image.network(
            arteDoStreamer(login),
            width: _larguraDoBanner,
            height: _alturaDoBanner,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
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
                // No art, no texture and no column: see [_FundoTextura],
                // [_Emblema] and [_SondaDeArte] for why both layers have to
                // be a mount decision rather than a fallback drawn inside a
                // widget that is always there.
                if (_temArte) _FundoTextura(login: canal.canal),
                _Lavagem(accent: accent),
                if (_temArte)
                  _Emblema(login: canal.canal, wide: widget.wide)
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
  /// A fixed pixel width now, not a fraction of the row's own width: the
  /// emblem's real size comes from the card's height (see
  /// [_proporcaoEmblemaPorAltura]), which has nothing to do with how wide
  /// this particular card happens to be, so there is no `LayoutBuilder` to
  /// read a width from any more.
  Widget _linha() => Row(
    children: [
      // Only when there is art. Reserving it anyway indented every
      // art-less card by the column's width and cut `7 assistindo` off the
      // end of a phone — space held for a picture that was never coming.
      if (_temArte)
        SizedBox(
          width:
              (widget.wide ? _larguraEmblemaWide : _larguraEmblemaEstreita) +
              (widget.wide ? 0 : 12),
        ),
      Expanded(child: _fatos()),
    ],
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
