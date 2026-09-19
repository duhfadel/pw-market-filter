import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/registro.dart';
import '../../domain/registro_filter.dart';

/// Which attributes matter, as seven toggles.
///
/// The long name and not `Atk F`: there is room here, and the short form is
/// jargon to somebody who has not opened the NPC's window yet. The grid uses
/// the short one, where the room is the constraint.
class AtributoFiltros extends StatelessWidget {
  const AtributoFiltros({
    required this.query,
    required this.acesos,
    required this.total,
    required this.aoAlternar,
    required this.aoLimpar,
    super.key,
  });

  final RegistroQuery query;

  /// How many slots the filter lights, and out of how many. Without it a
  /// filter that lights nothing looks like a broken grid instead of an answer
  /// — and "nenhum dá isso nesta aba" is a real answer.
  final int acesos;
  final int total;

  final void Function(RegistroAtributo) aoAlternar;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            'MOSTRAR OS QUE DÃO',
            style: TextStyle(
              color: PWColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (query.pedeAlgo)
            TextButton(
              onPressed: aoLimpar,
              style: TextButton.styleFrom(
                foregroundColor: PWColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('limpar'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final atributo in RegistroAtributo.values)
            _Toggle(
              rotulo: atributo.longo,
              ligado: query.atributos.contains(atributo),
              aoTocar: () => aoAlternar(atributo),
            ),
        ],
      ),
      if (query.pedeAlgo) ...[
        const SizedBox(height: 10),
        Text(
          acesos == 0
              ? 'Nenhum registro desta aba dá isso.'
              : '$acesos de $total nesta aba',
          style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
        ),
      ],
    ],
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.rotulo,
    required this.ligado,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ligado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: ligado ? PWColors.accent : PWColors.surfaceRaised,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 12.5,
            color: ligado ? PWColors.background : PWColors.textMuted,
            fontWeight: ligado ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}
