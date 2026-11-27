import 'package:flutter/material.dart';

import '../../../../../core/theme/pw_colors.dart';
import '../../../../../core/widgets/game_icon.dart';
import '../../../../../market/ocupacoes.dart';
import '../../../domain/jogador.dart';

/// A player as a small chip — the unit the war room moves around, both in
/// the pool of unplaced players and inside a group's body.
///
/// The grab handle (`⠿`) is drawn on every chip and is the one thing that
/// drags — see `_Pega` below, which mirrors
/// `instancias/ui/widgets/tabela_de_instancias.dart`'s `_PegaArrasto`: a
/// dedicated, small, immediate `Draggable`, never the whole chip. Grabbing a
/// tiny handle at the chip's edge does not steal the page's vertical scroll
/// the way dragging the whole row would, which is why no long-press gate is
/// needed here either — the same call the instance table already made and
/// `CLAUDE.md` records.
///
/// [lider] and the two callbacks travel together — a chip inside a group
/// gets a crown to toggle leadership and a cross to send the player back to
/// the pool; a chip in the pool gets neither, because there is no leader to
/// mark and nothing closer than "remove" to offer (placing one happens by
/// dropping it into a group, not from the pool chip itself).
///
/// The name is `Flexible` with ellipsis on purpose — a chip sits inside a
/// card whose width is not this widget's to decide, and a long nickname
/// must never push the attack level or the crown off the edge.
class ChipJogador extends StatelessWidget {
  const ChipJogador({
    required this.jogador,
    this.corGrupo,
    this.lider = false,
    this.onAlternarLider,
    this.onRemover,
    super.key,
  });

  final Jogador jogador;

  /// The group's own colour, read for the leader crown's tint only. Null
  /// outside a group, where there is no crown to tint.
  final Color? corGrupo;

  final bool lider;

  /// Non-null only for a chip drawn inside a group — shows the ♛.
  final VoidCallback? onAlternarLider;

  /// Non-null only for a chip drawn inside a group — shows the ✕.
  final VoidCallback? onRemover;

  @override
  Widget build(BuildContext context) {
    final classe = jogador.classe;
    final occu = classe == null ? null : ocupacaoDaClasse[classe];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: PWColors.elevado,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PWColors.filete),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pega(jogador: jogador),
          const SizedBox(width: 6),
          if (occu != null) ...[
            ClassIcon(occu, size: 20),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              jogador.nome,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: PWColors.papel, fontSize: 13),
            ),
          ),
          if (jogador.nivelAtaque != null) ...[
            const SizedBox(width: 6),
            // The attack level, never in the display face — a number
            // someone is deciding a war line-up on.
            Text(
              'NA ${jogador.nivelAtaque}',
              style: const TextStyle(color: PWColors.apagado, fontSize: 12),
            ),
          ],
          if (onAlternarLider != null)
            _Botao(
              glifo: '♛',
              cor: lider
                  ? (corGrupo ?? PWColors.accent)
                  : PWColors.apagado.withValues(alpha: 0.45),
              onTap: onAlternarLider!,
              tooltip: lider ? 'Tirar liderança' : 'Tornar líder',
            ),
          if (onRemover != null)
            _Botao(
              glifo: '✕',
              cor: PWColors.apagado,
              onTap: onRemover!,
              tooltip: 'Tirar da pt',
            ),
        ],
      ),
    );
  }
}

/// The `⠿` handle — the only part of a chip that starts a drag.
///
/// `Draggable` and not `LongPressDraggable`, mirroring the instance table's
/// own `_PegaArrasto`: the handle is a small, dedicated target, so grabbing
/// it does not fight a finger's vertical scroll the way an immediate drag
/// over the whole chip would. The rest of the chip — name, crown, cross —
/// stays a plain tap.
class _Pega extends StatelessWidget {
  const _Pega({required this.jogador});

  final Jogador jogador;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Arraste para mover',
    child: MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<String>(
        data: jogador.id,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _Fantasma(jogador: jogador),
        // The handle fades at its own spot while a copy of it flies with
        // the pointer — the same signal the instance table's pega gives.
        childWhenDragging: Opacity(opacity: 0.2, child: _glifo()),
        child: _glifo(),
      ),
    ),
  );

  Widget _glifo() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    child: Text('⠿', style: TextStyle(color: PWColors.apagado, fontSize: 13)),
  );
}

/// What flies with the pointer during a drag — a small, self-contained copy
/// of the chip's identity, never sized by (or sizing) the row it came from:
/// `feedback` paints in the overlay, outside any `Row`'s constraints.
class _Fantasma extends StatelessWidget {
  const _Fantasma({required this.jogador});

  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    final classe = jogador.classe;
    final occu = classe == null ? null : ocupacaoDaClasse[classe];
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PWColors.elevado,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PWColors.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (occu != null) ...[
              ClassIcon(occu, size: 20),
              const SizedBox(width: 6),
            ],
            Text(
              jogador.nome,
              style: const TextStyle(color: PWColors.papel, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Botao extends StatelessWidget {
  const _Botao({
    required this.glifo,
    required this.cor,
    required this.onTap,
    required this.tooltip,
  });

  final String glifo;
  final Color cor;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(glifo, style: TextStyle(color: cor, fontSize: 14)),
      ),
    ),
  );
}
