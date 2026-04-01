import "package:flutter/material.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme => ThemeData.from(colorScheme: this).copyWith(
    cardTheme: CardThemeData(color: primaryContainer),
    appBarTheme: AppBarTheme(
      titleSpacing: 0,
      backgroundColor: surfaceContainerLow,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(primaryContainer),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: TextStyle(color: onPrimary),
      color: WidgetStatePropertyAll(primary),
    ),
    textTheme: ThemeData(
      fontFamilyFallback: ["sans", "emoji"],
      brightness: brightness,
    ).textTheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
