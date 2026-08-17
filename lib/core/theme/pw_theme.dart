import 'package:flutter/material.dart';

import 'pw_colors.dart';

abstract final class PWTheme {
  /// The one face that is not Roboto, and it is for headings only.
  ///
  /// Body text, every figure and the whole filter stay on Roboto: the result
  /// cards are dense on purpose and a display face would cost them the line
  /// height they are tuned to. What this is for is the two places a visitor
  /// reads before deciding whether to stay — the front page's headline and the
  /// name of a tool.
  ///
  /// **Never put a number in it.** Marcellus draws Roman figures: its 1 has no
  /// flag and its 0 is barely distinguishable from an O, so "150 TCC" reads as
  /// "I5O TCC" — checked against the actual file, not assumed. Every price,
  /// count and attribute on this site is a number somebody is deciding money
  /// on, and they all stay on Roboto.
  ///
  /// Accented capitals were checked before adopting it — Á À Â Ã É Ê Í Ó Ô Õ Ú
  /// Ü Ç all draw, which the game's vocabulary needs.
  static const display = 'Marcellus';

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: PWColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: PWColors.accent,
        onPrimary: PWColors.background,
        surface: PWColors.surface,
        onSurface: PWColors.text,
        error: PWColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: PWColors.text,
        displayColor: PWColors.text,
      ),
      dividerTheme: const DividerThemeData(
        color: PWColors.border,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: PWColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: _inputBorder(PWColors.border),
        enabledBorder: _inputBorder(PWColors.border),
        focusedBorder: _inputBorder(PWColors.accent),
        labelStyle: const TextStyle(color: PWColors.textMuted),
        hintStyle: const TextStyle(color: PWColors.textMuted),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(PWColors.surfaceRaised),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}
