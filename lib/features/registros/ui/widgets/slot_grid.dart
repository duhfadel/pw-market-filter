import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../domain/registro.dart';
import '../../domain/registro_filter.dart';

/// The NPC's window, redrawn.
///
/// **Eight slots a row, on every screen.** That is what the game uses and what
/// the tab counts confirm: Área 1 and Área 2 are exactly 32, four rows of
/// eight, and Coletar is exactly 16.
///
/// It dropped to four columns on a phone at first, so each slot would stay
/// bigger than a fingertip. The owner asked for eight everywhere and named the
/// reason: somebody with the game in one window and this in another is
/// matching slot *positions*, and a grid that reflows to four columns is no
/// longer the same picture — which was the entire reason to draw a grid
/// instead of a list. At 390 px a slot lands near 40 px, under the 44 px a tap
/// target wants, and that is the price of the match.
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
    required this.compacto,
    super.key,
  });

  final List<Registro> slots;
  final RegistroQuery query;
  final Registro? selecionado;
  final void Function(Registro) aoTocar;

  /// A narrow screen. The eight columns stay, so what gives is the breathing
  /// room and the type size.
  final bool compacto;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemCount: slots.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 8,
      // The gaps shrink before the slots do: four pixels given back is four
      // pixels of slot, and on a 390 px screen that is a tenth of each one.
      mainAxisSpacing: compacto ? 6 : 8,
      crossAxisSpacing: compacto ? 4 : 8,
      // Taller than wide: the icon is square and the name sits under it. One
      // ratio for every tile is all a GridView can express, so it is set for
      // the longest name rather than the average — a name clipped mid-word
      // names nothing. A narrow screen needs proportionally more of that
      // height, because the name wraps sooner.
      childAspectRatio: compacto ? 0.56 : 0.72,
    ),
    itemBuilder: (context, i) => _Slot(
      registro: slots[i],
      aceso: atende(slots[i], query),
      escolhido:
          slots[i].ordem == selecionado?.ordem &&
          slots[i].aba == selecionado?.aba,
      aoTocar: () => aoTocar(slots[i]),
      compacto: compacto,
    ),
  );
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.registro,
    required this.aceso,
    required this.escolhido,
    required this.aoTocar,
    required this.compacto,
  });

  final Registro registro;
  final bool aceso;
  final bool escolhido;
  final VoidCallback aoTocar;
  final bool compacto;

  /// Every recipe in the window draws the same page art, so the icon is the
  /// section's emblem rather than an identity. That is why the name is under
  /// it and not instead of it.
  static const _arte = 83070;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: escolhido,
    label: registro.nome,
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        // Dimmed, never removed: the grid's positions are the whole reason it
        // is a grid, and the visitor is matching it against the window on
        // their own screen.
        opacity: aceso ? 1 : 0.28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: PWColors.surfaceRaised,
                borderRadius: BorderRadius.circular(compacto ? 6 : 9),
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
                    // Fills the slot instead of floating small inside it. The
                    // source is 32 px and is upscaled on purpose: the art is
                    // the same on all 126 recipes, so its job here is to fill
                    // a frame, not to be read.
                    const FittedBox(
                      fit: BoxFit.cover,
                      child: ItemIcon(_arte, size: 32),
                    ),
                    // A recipe nobody has read says so on the slot and not
                    // only in the panel, or the gaps stay invisible until
                    // somebody taps each one.
                    if (registro.semDados)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Icon(
                            Icons.help_outline,
                            size: compacto ? 9 : 13,
                            color: PWColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compacto ? 3 : 5),
            Expanded(
              child: Text(
                // The prefix is on all 126 of them and says nothing; what
                // tells them apart is what comes after the colon.
                registro.nome.replaceFirst(RegExp(r'^Registro:\s*'), ''),
                textAlign: TextAlign.center,
                maxLines: compacto ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compacto ? 8 : 10.5,
                  height: 1.2,
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
