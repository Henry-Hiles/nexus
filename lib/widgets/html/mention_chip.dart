import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/helpers/extensions/open_link_info.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/room_summary.dart";

class const MentionChip(final String content, final String? roomId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkInfo = content.linkInfo;
    final mention = linkInfo?.identifier;
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
                  RoomSummaryController.provider(
                    .new(roomIdOrAlias: mention!, via: linkInfo!.via),
                  ),
                )
                .whenOrNull(data: (data) => data) ??
            RoomSummary(roomId: mention),

      _ => null,
    };

    return mention == null
        ? SizedBox.shrink()
        : InkWell(
            onTap: () => ref.openLinkInfo(context, linkInfo!, roomId: roomId),
            child: Text(
              switch (data) {
                RoomSummary summary =>
                  "${(summary.name == null ? null : "#${summary.name}") ?? summary.canonicalAlias ?? summary.roomId}${linkInfo?.eventId == null ? "" : " > ${linkInfo?.eventId}"}",
                MembershipContent membership =>
                  membership.displayName == null
                      ? mention
                      : "@${membership.displayName}",
                _ => mention,
              },
              style: .new(
                fontWeight: .bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
  }
}
