import 'package:flutter/material.dart';

import 'pw_colors.dart';

abstract final class PWTheme {
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
