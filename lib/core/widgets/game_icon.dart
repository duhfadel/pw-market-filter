import 'package:flutter/material.dart';

import '../theme/pw_colors.dart';

/// An item's picture, downloaded by `tool/fetch_icons.dart`.
///
/// Falls back to an empty box of the same size when the file is missing —
/// which happens for any item that entered the market since the last icon
/// fetch. A gap in the row is a much smaller problem than a broken layout, and
/// the name is always beside it anyway.
class ItemIcon extends StatelessWidget {
  const ItemIcon(this.itemId, {this.size = 26, super.key});

  final int itemId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      'assets/icons/items/$itemId.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// Uma pedra do set, sem a moldura nem o fundo.
///
/// **Vem de `assets/icons/pedras/` e não de `items/`**, que é partilhada por
/// toda a app: o mesmo ficheiro recortado estragaria as tiras de pedra do
/// card, onde a moldura é o que separa um encaixe do seguinte.
///
/// Só as cinco de equipamento existem recortadas — ver
/// `tool/pedras/recortar.py` para porque as de acessório não cortam. Uma que
/// falte desenha nada, como o [ItemIcon].
class StoneIcon extends StatelessWidget {
  const StoneIcon(this.itemId, {this.size = 20, super.key});

  final int itemId;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Image.asset(
      'assets/icons/pedras/$itemId.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// A class's portrait, keyed by the `occupation` number the listing carries.
class ClassIcon extends StatelessWidget {
  const ClassIcon(this.occupation, {this.size = 24, super.key});

  final int occupation;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: Container(
        color: PWColors.surfaceRaised,
        child: Image.asset(
          'assets/icons/classes/$occupation.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
