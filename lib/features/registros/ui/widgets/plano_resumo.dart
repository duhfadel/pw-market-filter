import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/plano.dart';
import '../../domain/registro.dart';

/// What the marked recipes cost, in pages.
///
/// **Both halves of the trade**, which is the whole point: what it costs in
/// pages, and what the character ends up with. The game shows neither — it
/// prints a recipe at a time and never adds anything.
///
/// The cost matters because the tabs are wildly uneven and nothing said so:
/// Área 1 is 32 pages for thirty-two recipes and Área 2 is 343 for the same
/// count. The gain matters because it is the reason to spend at all.
///
/// The attributes are listed one by one and never added together. Summing
/// inside an attribute is a real quantity; summing across them was the number
/// taken off the panel, and it stays off.
///
/// **It counts across tabs**, because planning does. Marking five in Área 1
/// and three in Coletar is one plan, and a total that reset on every tab
/// would answer a question nobody asked.
class PlanoResumo extends StatelessWidget {
  const PlanoResumo({
    required this.plano,
    required this.temQueMarcar,
    required this.aoMarcarAba,
    required this.aoLimpar,
    super.key,
  });

  final Plano plano;

  /// Whether the open tab still has a lit slot left to mark. When it does not,
  /// offering to mark them is a button that does nothing.
  final bool temQueMarcar;

  final VoidCallback aoMarcarAba;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: plano.vazio ? PWColors.border : PWColors.accent,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plano.vazio)
          const Text(
            'Marque registros para somar quantas páginas eles custam.',
            style: TextStyle(color: PWColors.textMuted, fontSize: 13),
          )
        else ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: plano.registros == 1
                      ? '1 registro'
                      : '${plano.registros} registros',
                ),
                const TextSpan(text: '  ·  '),
                TextSpan(
                  text: plano.paginas == 1
                      ? '1 página'
                      : '${plano.paginas} páginas',
                  style: const TextStyle(
                    color: PWColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: const TextStyle(color: PWColors.text, fontSize: 15),
          ),
          // What the character ends up with, attribute by attribute. This is
          // the half the visitor is buying, and the game never adds it up.
          if (plano.pontos.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final ponto in plano.pontos.entries)
                  _Ganho(atributo: ponto.key, valor: ponto.value),
              ],
            ),
          ],
          // Said out loud rather than folded in as zero: a total that silently
          // omits an unknown cost reads as complete while being short.
          if (plano.semCusto > 0) ...[
            const SizedBox(height: 5),
            Text(
              plano.semCusto == 1
                  ? '+ 1 registro cujo custo ninguém registrou ainda'
                  : '+ ${plano.semCusto} registros cujo custo ninguém '
                        'registrou ainda',
              style: const TextStyle(
                color: PWColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (temQueMarcar)
              TextButton.icon(
                onPressed: aoMarcarAba,
                icon: const Icon(Icons.done_all, size: 17),
                // "o que está na tela" and not "a aba": with a filter on, this
                // marks the lit slots only, and the label has to say what the
                // button will actually do.
                label: const Text('Somar o que está na tela'),
                style: TextButton.styleFrom(
                  foregroundColor: PWColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            if (!plano.vazio)
              TextButton.icon(
                onPressed: aoLimpar,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('limpar'),
                style: TextButton.styleFrom(
                  foregroundColor: PWColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// One attribute's total across the whole plan.
class _Ganho extends StatelessWidget {
  const _Ganho({required this.atributo, required this.valor});

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
