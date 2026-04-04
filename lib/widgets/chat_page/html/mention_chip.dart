import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/user_controller.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";

class MentionChip extends ConsumerWidget {
  final String content;
  const MentionChip(this.content, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = content.mention.startsWith("@") == true
        ? ref
              .watch(UserController.provider(content.mention))
              .whenOrNull(data: (data) => data)
        : null;

    return InkWell(
      onTapUp: (details) {
        content.mention;
        if (membership != null) {
          context.showUserPopover(
            membership,
            globalPosition: details.globalPosition,
          );
        }
      },
      child: IgnorePointer(
        child: Chip(
          label: Text(
            (membership == null ? null : "@${membership.displayName}") ??
                content.mention,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
