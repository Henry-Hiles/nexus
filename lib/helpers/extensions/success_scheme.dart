import "package:dynamic_color/dynamic_color.dart";
import "package:material_ui/material_ui.dart";

extension SuccessScheme on ThemeData {
  /// Green colors for positive things, like accepting knocks or new pins,
  /// harmonized so they fit the current theme.
  ColorScheme get successScheme => ColorScheme.fromSeed(
    seedColor: Colors.green.harmonizeWith(colorScheme.primary),
    brightness: brightness,
  );
}
