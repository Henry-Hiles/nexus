import "package:material_ui/material_ui.dart";

extension SchemeToTheme on ColorScheme {
  ThemeData get theme {
    final textTheme = ThemeData(
      fontFamily: "bundled-sans",
      fontFamilyFallback: ["emoji", "bundled-emoji"],
      brightness: brightness,
    ).textTheme;
    return .from(colorScheme: this).copyWith(
      cardTheme: .new(color: primaryContainer),
      badgeTheme: .new(backgroundColor: primary, textColor: onPrimary),
      popupMenuTheme: .new(
        shape: RoundedRectangleBorder(borderRadius: .circular(16)),
        color: surfaceContainerHigh,
      ),
      appBarTheme: AppBarTheme(
        titleSpacing: 0,
        backgroundColor: surfaceContainerLow,
      ),
      tooltipTheme: .new(
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: .w600,
        ),
        padding: .all(8),
        decoration: BoxDecoration(
          color: surfaceContainerHighest,
          borderRadius: .circular(8),
        ),
      ),
      iconButtonTheme: .new(variant: .material3Expressive),
      textTheme: textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
