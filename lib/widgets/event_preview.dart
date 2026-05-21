import "package:flutter/material.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

class EventPreview extends StatelessWidget {
  final Event event;
  const EventPreview(this.event, {super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 12,
        children: [
          if (event.content is MessageContent) MessageAvatar(event),

          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                if (event.content is MessageContent) MessageDisplayname(event),
                EventRenderer(event, textOnly: true, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
