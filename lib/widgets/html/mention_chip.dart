import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/room_summary.dart";

class MentionChip extends ConsumerWidget {
  final String? roomId;
  final String content;
  const MentionChip(this.content, this.roomId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mention = content.mention;
    final data = switch (mention?.characters.firstOrNull) {
      "@" =>
        ref
            .watch(
              UserController.provider(.new(roomId: roomId, userId: mention!)),
            )
            .whenOrNull(data: (data) => data),

      "#" || "!" =>
        ref
            .watch(
              RoomSummaryController.provider(.new(roomIdOrAlias: mention!)),
            )
            .whenOrNull(data: (data) => data),

      _ => null,
    };

    return mention == null
        ? SizedBox.shrink()
        : InkWell(
            onTap: () {
              if (data case MembershipContent membership) {
                context.showUserPopover(membership, mention, roomId: roomId);
              } else if (data case RoomSummary summary) {
                // TODO: Handle summary
              }
            },
            child: IgnorePointer(
              child: Chip(
                label: Text(
                  switch (data) {
                    RoomSummary summary =>
                      (summary.name == null ? null : "#${summary.name}") ??
                          summary.canonicalAlias ??
                          summary.roomId,
                    MembershipContent membership =>
                      membership.displayName == null
                          ? mention
                          : "@${membership.displayName}",
                    _ => mention,
                  },
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
