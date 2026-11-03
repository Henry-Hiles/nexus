import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/widgets/room_summary_sheet.dart";

extension OpenLinkInfo on WidgetRef {
  Future<void> openLinkInfo(
    BuildContext context,
    LinkInfo linkInfo, {
    String? roomId,
  }) async {
    final identifier = linkInfo.identifier;
    if (identifier.startsWith("@")) {
      context.showUserPopover(identifier, roomId: roomId);
      return;
    }

    final request = RoomSummaryController.provider(
      .new(roomIdOrAlias: identifier, via: linkInfo.via),
    );
    final summary = await read(request.future)
        .onError((_, _) => RoomSummary(roomId: identifier));

    final eventRowId = linkInfo.eventId == null
        ? null
        : await read(
            EventController.provider(
              .new(roomId: summary.roomId, eventId: linkInfo.eventId!),
            ).selectAsync((data) => data?.rowId),
          ).onError((_, _) => null);

    if (await focusRoom(summary.roomId, eventRowId) || !context.mounted) return;

    await context.showAdaptiveSheet(
      (context) => Consumer(
        builder: (context, ref, _) => RoomSummarySheet(
          ref.watch(request).whenOrNull(data: (data) => data) ?? summary,
          via: linkInfo.via,
        ),
      ),
    );
  }
}
