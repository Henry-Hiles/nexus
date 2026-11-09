import "package:material_ui/material_ui.dart";
import "package:m3e_design/m3e_design.dart";

// Needed for navigation_rail_m3e (#65).
import "package:flutter/material.dart" as old_mat;

/// Themes a navigation_rail_m3e rail, which still uses the old Material theme.
class const M3ERailTheme({
  required final WidgetBuilder builder,
  final List<old_mat.ThemeExtension> extensions = const [],
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialUiCompatibilityBridge(
    child: Builder(
      builder: (context) {
        final theme = old_mat.Theme.of(context);
        return old_mat.Theme(
          data: theme.copyWith(
            extensions: [
              ...extensions,
              // Otherwise the FAB label falls back to Roboto
              M3ETheme.defaults(theme.colorScheme).copyWith(
                typography: .defaultFor(
                  theme.brightness,
                  baseOverride: theme.textTheme,
                ),
              ),
            ],
          ),
          child: Builder(builder: builder),
        );
      },
    ),
  );
}
