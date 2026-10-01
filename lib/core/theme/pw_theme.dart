import 'package:flutter/material.dart';

import 'pw_colors.dart';

abstract final class PWTheme {
  /// The one face that is not Inter, and it is for headings only.
  ///
  /// Body text, every figure and the whole filter stay on Inter: the result
  /// cards are dense on purpose and a display face would cost them the line
  /// height they are tuned to. What this is for is the two places a visitor
  /// reads before deciding whether to stay — the front page's headline and the
  /// name of a tool.
  ///
  /// **Never put a number in it.** Marcellus draws Roman figures: its 1 has no
  /// flag and its 0 is barely distinguishable from an O, so "150 TCC" reads as
  /// "I5O TCC" — checked against the actual file, not assumed. Every price,
  /// count and attribute on this site is a number somebody is deciding money
  /// on, and they all stay on Inter.
  ///
  /// Accented capitals were checked before adopting it — Á À Â Ã É Ê Í Ó Ô Õ Ú
  /// Ü Ç all draw, which the game's vocabulary needs.
  static const display = 'Marcellus';

  /// The body face, and every figure on the site.
  ///
  /// **Roboto was the face Flutter hands you when you have not chosen one**,
  /// and it was in every price, count and attribute here. Inter is a drop-in
  /// in metrics and texture but is drawn for screens, and it carries the
  /// feature below.
  static const body = 'Inter';

  /// Figures that line up in a column.
  ///
  /// A site of prices lives or dies on this: with proportional figures `1111`
  /// is narrower than `8888`, so a column of them does not align and comparing
  /// two prices becomes reading them. `tnum` gives every digit the same
  /// advance width.
  ///
  /// Copied onto each style rather than passed to `TextTheme.apply`, which
  /// takes a family and colours but no font features.
  static const _figuras = [FontFeature.tabularFigures()];

  static TextTheme _comFiguras(TextTheme t) => TextTheme(
    displayLarge: t.displayLarge?.copyWith(fontFeatures: _figuras),
    displayMedium: t.displayMedium?.copyWith(fontFeatures: _figuras),
    displaySmall: t.displaySmall?.copyWith(fontFeatures: _figuras),
    headlineLarge: t.headlineLarge?.copyWith(fontFeatures: _figuras),
    headlineMedium: t.headlineMedium?.copyWith(fontFeatures: _figuras),
    headlineSmall: t.headlineSmall?.copyWith(fontFeatures: _figuras),
    titleLarge: t.titleLarge?.copyWith(fontFeatures: _figuras),
    titleMedium: t.titleMedium?.copyWith(fontFeatures: _figuras),
    titleSmall: t.titleSmall?.copyWith(fontFeatures: _figuras),
    bodyLarge: t.bodyLarge?.copyWith(fontFeatures: _figuras),
    bodyMedium: t.bodyMedium?.copyWith(fontFeatures: _figuras),
    bodySmall: t.bodySmall?.copyWith(fontFeatures: _figuras),
    labelLarge: t.labelLarge?.copyWith(fontFeatures: _figuras),
    labelMedium: t.labelMedium?.copyWith(fontFeatures: _figuras),
    labelSmall: t.labelSmall?.copyWith(fontFeatures: _figuras),
  );

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: PWColors.noite,
      colorScheme: base.colorScheme.copyWith(
        primary: PWColors.accent,
        onPrimary: PWColors.noite,
        surface: PWColors.painel,
        onSurface: PWColors.papel,
        error: PWColors.danger,
      ),
      cardTheme: const CardThemeData(color: PWColors.painel),
      textTheme: _comFiguras(
        base.textTheme.apply(
          fontFamily: body,
          bodyColor: PWColors.papel,
          displayColor: PWColors.papel,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PWColors.filete,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: PWColors.elevado,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: _inputBorder(PWColors.filete),
        enabledBorder: _inputBorder(PWColors.filete),
        focusedBorder: _inputBorder(PWColors.accent),
        labelStyle: const TextStyle(color: PWColors.apagado),
        hintStyle: const TextStyle(color: PWColors.apagado),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(PWColors.elevado),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}
