import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/displayname_color.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/hooks/tap_recognizer.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/generic_event.dart";
import "package:nexus/widgets/user_span.dart";

class const MembershipRenderer(
  final Event event, {
  final int? maxLines,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      event.content is MembershipContent,
      "Make sure to only pass membership events to MembershipRenderer",
    );

    final targetRecognizer = useTapRecognizer();
    final senderRecognizer = useTapRecognizer();
    final previous = switch (event.previousContent) {
      MembershipContent(:final status) => status,
      _ => null,
    };

    return switch (event.content) {
      MembershipContent content => GenericEventRenderer(
        Icons.people,
        maxLines: maxLines,
        [
          UserSpan(
            context,
            content.displayName ?? event.stateKey!.localpart,
            userId: event.stateKey!,
            roomId: event.roomId,
            recognizer: targetRecognizer,
            style: .new(
              color: ref.displaynameColor(event.roomId, event.stateKey!),
              fontWeight: .bold,
            ),
          ),
          TextSpan(
            text:
                "${switch (content.status) {
                  .invite => previous == .knock ? "was accepted into" : "was invited to",
                  .join => "joined",
                  .leave when previous == .knock => event.sender == event.stateKey ? "retracted their knock on" : "had their knock denied in",
                  .leave => event.sender == event.stateKey ? "left" : (previous == .ban ? "was unbanned from" : "was kicked from"),
                  .ban => "was banned from",
                  .knock => "asked to join",
                  .unknown => "changed their membership in",
                }} the room${event.sender == event.stateKey ? "" : " by"}",
          ),
          if (event.sender != event.stateKey)
            UserSpan.sender(context, ref, event, recognizer: senderRecognizer),
          if (content.reason != null)
            TextSpan(text: "for \"${content.reason}\""),
        ],
      ),
      _ => SizedBox.shrink(),
    };
  }
}
