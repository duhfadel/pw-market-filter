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
                child: _Card(
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

class _Card extends StatelessWidget {
  const _Card({required this.canal, required this.wide, super.key});

  final CanalAoVivo canal;
  final bool wide;

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
        padding: EdgeInsets.all(wide ? 16 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PWColors.border),
        ),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  const SizedBox(height: 3),
                  Text(
                    _abaixo(canal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PWColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward,
              size: 18,
              color: PWColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );

  /// What is under the name: the game and the audience, when they are known.
  ///
  /// The title of the stream is deliberately left out. It is written for the
  /// Twitch page — full of emoji, coupons and `!commands` — and pasted here it
  /// reads as spam on somebody else's site.
  static String _abaixo(CanalAoVivo canal) {
    final partes = <String>[
      'ao vivo na Twitch',
      if (canal.jogo != null && canal.jogo!.isNotEmpty) canal.jogo!,
      if (canal.espectadores != null)
        canal.espectadores == 1
            ? '1 assistindo'
            : '${canal.espectadores} assistindo',
    ];
    return partes.join('  ·  ');
  }
}
