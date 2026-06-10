import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/user_controller.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";

class MentionChip extends ConsumerWidget {
  final String? roomId;
  final String content;
  const MentionChip(this.content, this.roomId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mention = content.mention;
    final membership = mention?.startsWith("@") == true
        ? ref
              .watch(
                UserController.provider(.new(roomId: roomId, userId: mention!)),
              )
              .whenOrNull(data: (data) => data)
        : null;

    return mention == null
        ? SizedBox.shrink()
        : InkWell(
            onTapUp: (details) {
              if (membership != null) {
                context.showUserPopover(membership, mention, roomId: roomId);
              }
            },
            child: IgnorePointer(
              child: Chip(
                label: Text(
                  (membership?.displayName == null
                          ? null
                          : "@${membership!.displayName}") ??
                      mention,
                  style: .new(
                    fontWeight: .bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
  }
}
