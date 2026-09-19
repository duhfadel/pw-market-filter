import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/registro.dart';

/// What the chosen slot grants, below the grid.
///
/// Below and fixed, where the game puts *Requer / Habilidade / Item*: clicking
/// another slot swaps the contents, so two recipes can be compared without
/// opening and closing anything. A floating tooltip would cover the grid on a
/// phone, which is the one place comparing is already hardest.
class RegistroPanel extends StatelessWidget {
  const RegistroPanel({required this.registro, super.key});

  /// `null` before the first tap. The panel then invites one rather than
  /// standing as an empty frame.
  final Registro? registro;

  @override
  Widget build(BuildContext context) {
    final escolhido = registro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PWColors.border),
      ),
      child: escolhido == null
          ? const Text(
              'Toque num registro para ver o que ele dá.',
              style: TextStyle(color: PWColors.textMuted, fontSize: 13),
            )
          : _Conteudo(registro: escolhido),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.registro});

  final Registro registro;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        registro.nome,
        style: const TextStyle(
          color: PWColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _custo(registro),
        style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
      ),
      const SizedBox(height: 14),
      if (registro.semDados)
        // Said plainly, and as a fact about this site rather than about the
        // game: seven zeros here would have the page assert that the recipe
        // grants nothing, which nobody has checked.
        const Row(
          children: [
            Icon(Icons.help_outline, size: 16, color: PWColors.textMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ainda não sabemos o que este registro dá. '
                'Se você souber, me conta no Discord.',
                style: TextStyle(color: PWColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        )
      else ...[
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final ponto in registro.pontos.entries)
              _Chip(atributo: ponto.key, valor: ponto.value),
          ],
        ),
        const SizedBox(height: 14),
        _Rodape(registro: registro),
      ],
    ],
  );

  /// `null` pages is not free, and must not read as free.
  static String _custo(Registro r) => switch (r.paginas) {
    null => 'custo não registrado',
    1 => '1 página',
    final n => '$n páginas',
  };
}

class _Chip extends StatelessWidget {
  const _Chip({required this.atributo, required this.valor});

  final RegistroAtributo atributo;
  final int valor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: PWColors.border),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${atributo.curto} '),
          TextSpan(
            text: '+$valor',
            style: const TextStyle(
              color: PWColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      style: const TextStyle(color: PWColors.textMuted, fontSize: 13),
    ),
  );
}

/// The sum and the rate — the two numbers the game's window never shows.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.registro});

  final Registro registro;

  @override
  Widget build(BuildContext context) {
    final taxa = registro.porPagina;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${registro.total} pontos no total'),
          if (taxa != null) ...[
            const TextSpan(text: '  ·  '),
            TextSpan(
              // One decimal, and only when it says something: "118" reads
              // better than "118.0", and 0.9 has to keep its nine.
              text: '${_curto(taxa)} por página',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
      style: const TextStyle(
        color: PWColors.textMuted,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  static String _curto(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
