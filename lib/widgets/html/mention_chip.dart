import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/widgets/room_summary_dialog.dart";

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
                  RoomSummaryController.provider(.new(roomIdOrAlias: mention!)),
                )
                .whenOrNull(data: (data) => data) ??
            RoomSummary(roomId: mention),

      _ => null,
    };

    return mention == null
        ? SizedBox.shrink()
        : InkWell(
            onTap: () async {
              if (data case MembershipContent membership) {
                context.showUserPopover(membership, mention, roomId: roomId);
              } else if (data case RoomSummary summary) {
                // TODO: This is an extra call that isn't truly needed, get rid of it
                final eventRowId = linkInfo?.eventId == null
                    ? null
                    : await ref
                          .read(
                            EventController.provider(
                              .new(
                                roomId: summary.roomId,
                                eventId: linkInfo!.eventId!,
                              ),
                            ).selectAsync((data) => data?.rowId),
                          )
                          .onError((_, _) => null);

                if (!await ref.focusRoom(summary.roomId, eventRowId) &&
                    context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => Consumer(
                      builder: (context, ref, _) => RoomSummaryDialog(
                        ref
                                .watch(
                                  RoomSummaryController.provider(
                                    .new(roomIdOrAlias: mention),
                                  ),
                                )
                                .whenOrNull(data: (data) => data) ??
                            summary,
                        via: linkInfo?.via,
                      ),
                    ),
                  );
                }
              }
            },
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
