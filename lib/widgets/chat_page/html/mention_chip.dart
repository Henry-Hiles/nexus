import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/user_controller.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";

class MentionChip extends ConsumerWidget {
  final String label;
  const MentionChip(this.label, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mention = label.mention;
    final membership =
        mention?.startsWith("@") == true || label.startsWith("@") == true
        ? ref
              .watch(UserController.provider(mention ?? label))
              .whenOrNull(data: (data) => data)
        : null;

    return InkWell(
      onTapUp: (details) {
        if (membership != null) {
          context.showUserPopover(
            membership,
            globalPosition: details.globalPosition,
          );
        }
      },
      child: Chip(
        label: Text(
          (membership == null ? null : "@${membership.displayName}") ??
              mention ??
              label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
