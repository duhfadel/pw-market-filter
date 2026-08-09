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
