import "package:flutter/material.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:matrix/matrix.dart";

class MentionChip extends StatelessWidget {
  final String label;
  const MentionChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) => InlineCustomWidget(
    child: ActionChip(
      label: Text(
        label.parseIdentifierIntoParts()?.primaryIdentifier ?? label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onPressed: () {
        // TODO: Open room or join room dialog, or user popover
        showAboutDialog(context: context);
      },
    ),
  );
}
