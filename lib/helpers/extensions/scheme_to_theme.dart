import "package:flutter/material.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme => ThemeData.from(colorScheme: this).copyWith(
    cardTheme: CardThemeData(color: primaryContainer),
    appBarTheme: AppBarTheme(
      titleSpacing: 0,
      backgroundColor: surfaceContainerLow,
    ),
    textTheme: ThemeData(
      fontFamilyFallback: ["sans"],
      brightness: brightness,
    ).textTheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
