import "package:flutter/widgets.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/member_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/configs/member_config.dart";
import "package:nexus/models/room.dart";

class MessageDisplayname extends ConsumerWidget {
  final Message message;
  final Room room;
  final TextStyle? style;
  const MessageDisplayname(this.message, this.room, {this.style, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(
        MemberController.provider(
          MemberConfig(room: room, userId: message.authorId),
        ),
      )
      .betterWhen(
        data: (membership) => Text(
          membership.displayName,
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
        loading: SizedBox.shrink,
      );
}
