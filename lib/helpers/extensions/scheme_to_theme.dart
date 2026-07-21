import "package:flutter/material.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme {
    final textTheme = ThemeData(
      fontFamilyFallback: ["sans", "emoji", "fallback-sans", "fallback-emoji"],
      brightness: brightness,
    ).textTheme;
    return .from(colorScheme: this).copyWith(
      cardTheme: .new(color: primaryContainer),
      popupMenuTheme: .new(
        shape: RoundedRectangleBorder(borderRadius: .circular(16)),
        color: surfaceContainerHigh,
      ),
      appBarTheme: AppBarTheme(
        titleSpacing: 0,
        backgroundColor: surfaceContainerLow,
      ),
      tooltipTheme: .new(
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        padding: .all(8),
        decoration: BoxDecoration(
          color: surfaceContainerHighest,
          borderRadius: .circular(8),
        ),
      ),
      textTheme: textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
