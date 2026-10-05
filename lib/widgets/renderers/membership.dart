import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/generic_event.dart";

class const MembershipRenderer(
  final Event event, {
  final int? maxLines,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    assert(
      event.content is MembershipContent,
      "Make sure to only pass membership events to MembershipRenderer",
    );

    return switch (event.content) {
      MembershipContent content => GenericEventRenderer(
        Icons.people,
        maxLines: maxLines,
        [
          WidgetSpan(
            alignment: .middle,
            child: InkWell(
              onTap: () => context.showUserPopover(
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
          ),
          TextSpan(
            text:
                "${switch (content.status) {
                  .invite => "was invited to",
                  .join => "joined",
                  .leave => event.sender == event.stateKey ? "left" : (event.unsigned["prev_content"]?["membership"] == "ban" ? "was unbanned from" : "was kicked from"),
                  .ban => "was banned from",
                  .knock => "asked to join",
                }} the room${event.sender == event.stateKey ? "" : " by"}",
          ),
          if (event.sender != event.stateKey)
            WidgetSpan(
              alignment: .middle,
              child: MessageDisplayname(event, shouldWrap: maxLines == null),
            ),
          if (content.reason != null)
            TextSpan(text: "for \"${content.reason}\""),
        ],
      ),
      _ => SizedBox.shrink(),
    };
  }
}
