import "package:material_ui/material_ui.dart";

class const BannedWarningDialog({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text("View Banned Members?"),
    content: Text(
      "Banned members may have offensive or abusive display names and avatars.",
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text("Cancel"),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: Text("Continue and don't show again"),
      ),
    ],
  );
}
