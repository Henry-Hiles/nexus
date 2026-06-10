import "package:flutter/material.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/generic_event.dart";

class MembershipRenderer extends StatelessWidget {
  final Event event;
  const MembershipRenderer(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    assert(
      event.content is MembershipContent,
      "Make sure to only pass membership events to MembershipRenderer",
    );

    return switch (event.content) {
      MembershipContent content => GenericEventRenderer(Icons.people, [
        InkWell(
          onTapUp: (details) => context.showUserPopover(
            content,
            event.stateKey!,
            roomId: event.roomId,
          ),
          child: Text(
            overflow: .ellipsis,
            content.displayName ?? event.stateKey!.localpart,
            maxLines: 1,
            style: .new(color: event.sender.colorHash, fontWeight: .bold),
          ),
        ),
        Text(
          overflow: .ellipsis,
          maxLines: 1,
          "${switch (content.status) {
            .invite => "was invited to",
            .join => "joined",
            .leave => event.sender == event.stateKey ? "left" : (event.unsigned["prev_content"]?["membership"] == "ban" ? "was unbanned from" : "was kicked from"),
            .ban => "was banned from",
            .knock => "asked to join",
          }} the room${event.sender == event.stateKey ? "" : " by "}",
        ),
        if (event.sender != event.stateKey) MessageDisplayname(event),
        if (content.reason != null) Text("for \"${content.reason}\""),
      ]),
      _ => SizedBox.shrink(),
    };
  }
}
