import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

class const EventPreview(final Event event, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: .symmetric(vertical: 4),
      child: Row(
        mainAxisSize: .min,
        spacing: 10,
        children: [
          if (event.content is MessageContent) MessageAvatar(event, height: 40),

          Flexible(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .start,
              children: [
                if (event.content is MessageContent) MessageDisplayname(event),
                EventRenderer(
                  event.rowId,
                  roomId: event.roomId,
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
