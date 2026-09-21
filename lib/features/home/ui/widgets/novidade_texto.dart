import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/novidade.dart';

/// A Discord message, drawn.
///
/// Three things survive the trip — paragraphs, bold, links — and everything
/// else arrives as the characters somebody typed. Emoji come through as
/// themselves, which is why the lists in these announcements still read.
class NovidadeTexto extends StatelessWidget {
  const NovidadeTexto({required this.corpo, super.key});

  final String corpo;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final paragrafo in paragrafos(corpo))
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text.rich(
            TextSpan(children: [for (final p in pedacos(paragrafo)) _span(p)]),
            style: const TextStyle(
              color: PWColors.text,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ),
    ],
  );

  static InlineSpan _span(Pedaco pedaco) {
    final url = pedaco.url;
    if (url != null) {
      return TextSpan(
        text: pedaco.texto,
        style: const TextStyle(
          color: PWColors.accent,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: PWColors.accent,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => unawaited(
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
      );
    }

    return TextSpan(
      text: pedaco.texto,
      style: pedaco.negrito
          ? const TextStyle(fontWeight: FontWeight.w700)
          : null,
    );
  }
}
