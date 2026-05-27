import "package:flutter/material.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme => ThemeData.from(colorScheme: this).copyWith(
    cardTheme: CardThemeData(color: primaryContainer),
    appBarTheme: AppBarTheme(
      titleSpacing: 0,
      backgroundColor: surfaceContainerLow,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surfaceContainerHigh,
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
