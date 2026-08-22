import "package:material_ui/material_ui.dart";

class Setting({
  required final String title,
  required final String description,
  required final IconData icon,
  required final Widget Function(
    String title,
    String description,
    IconData icon,
  )
  builder,
});
