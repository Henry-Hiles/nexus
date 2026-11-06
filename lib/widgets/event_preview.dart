import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/is_shown_as_message.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

class const EventPreview(
  final int rowId, {
  required final String roomId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]?.events[rowId]),
    );
    if (event == null) return SizedBox.shrink();

    final showSender = event.hasMessageContent;

    return IgnorePointer(
      child: Padding(
        padding: .symmetric(vertical: 4),
        child: Row(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            if (showSender) MessageAvatar(event, height: 36),

            Flexible(
              child: Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .start,
                children: [
                  if (showSender) MessageDisplayname(event, shouldWrap: false),
                  EventRenderer(
                    rowId,
                    roomId: roomId,
                    textOnly: true,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
