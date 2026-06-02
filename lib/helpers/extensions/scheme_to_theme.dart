import "package:flutter/material.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme => .from(colorScheme: this).copyWith(
    cardTheme: .new(color: primaryContainer),
    popupMenuTheme: .new(
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      color: surfaceContainerHigh,
    ),
    appBarTheme: AppBarTheme(
      titleSpacing: 0,
      backgroundColor: surfaceContainerLow,
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
