import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../domain/registro.dart';
import '../../domain/registro_filter.dart';

/// The NPC's window, redrawn.
///
/// **Eight slots a row**, which is what the game uses and what the tab counts
/// confirm: Área 1 and Área 2 are exactly 32, four rows of eight, and Coletar
/// is exactly 16. On a phone eight would make each slot smaller than a
/// fingertip, so the count drops — the grid keeps its shape where the shape
/// fits and stays usable where it does not.
///
/// **Each slot carries its name.** The game does not, and this is the one
/// place the copy deliberately departs from it: thirty-two identical icons is
/// a limitation to leave behind, not to reproduce. A phone has no hover, so a
/// faithful copy would cost thirty-two taps to find one recipe.
class SlotGrid extends StatelessWidget {
  const SlotGrid({
    required this.slots,
    required this.query,
    required this.selecionado,
    required this.aoTocar,
    required this.colunas,
    super.key,
  });

  final List<Registro> slots;
  final RegistroQuery query;
  final Registro? selecionado;
  final void Function(Registro) aoTocar;
  final int colunas;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemCount: slots.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: colunas,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      // Taller than wide: the icon is square and the name sits under it. A
      // single ratio for every tile is all a GridView can express, so it is
      // set for the longest name rather than the average — a name clipped
      // mid-word names nothing.
      childAspectRatio: 0.72,
    ),
    itemBuilder: (context, i) => _Slot(
      registro: slots[i],
      aceso: atende(slots[i], query),
      escolhido:
          slots[i].ordem == selecionado?.ordem &&
          slots[i].aba == selecionado?.aba,
      aoTocar: () => aoTocar(slots[i]),
    ),
  );
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.registro,
    required this.aceso,
    required this.escolhido,
    required this.aoTocar,
  });

  final Registro registro;
  final bool aceso;
  final bool escolhido;
  final VoidCallback aoTocar;

  /// Every recipe in the window draws the same page art, so the icon is the
  /// section's emblem rather than an identity. That is why the name is under
  /// it and not instead of it.
  static const _arte = 83070;

  @override
  Widget build(BuildContext context) {
    // Dimmed, never removed: the grid's positions are the whole reason it is a
    // grid, and a player is matching it against the window on their screen.
    final opacidade = aceso ? 1.0 : 0.28;

    return Semantics(
      button: true,
      selected: escolhido,
      label: registro.nome,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: opacidade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: PWColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: escolhido ? PWColors.accent : PWColors.border,
                    width: escolhido ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fills the slot instead of floating small inside it.
                      // The source is 32 px and is upscaled on purpose: the
                      // art is the same on all 126 recipes, so its job here is
                      // to fill a frame, not to be read.
                      const FittedBox(
                        fit: BoxFit.cover,
                        child: ItemIcon(_arte, size: 32),
                      ),
                      // A recipe nobody has read says so on the slot, not only
                      // in the panel: otherwise the gaps are invisible until
                      // somebody clicks each one.
                      if (registro.semDados)
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.help_outline,
                              size: 13,
                              color: PWColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  // The prefix is on all 126 of them and says nothing; what
                  // tells them apart is what comes after the colon.
                  registro.nome.replaceFirst(RegExp(r'^Registro:\s*'), ''),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: escolhido ? PWColors.accent : PWColors.textMuted,
                    fontWeight: escolhido ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
