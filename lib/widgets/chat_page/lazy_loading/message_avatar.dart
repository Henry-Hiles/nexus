import "package:flutter/widgets.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/configs/author_config.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MessageAvatar extends ConsumerWidget {
  final Message message;
  final Room room;
  final double height;
  const MessageAvatar(this.message, this.room, {this.height = 16, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(
        AuthorController.provider(AuthorConfig(room: room, message: message)),
      )
      .betterWhen(
        data: (membership) => AvatarOrHash(
          membership.avatarUrl,
          membership.displayName,
          height: height,
        ),
        loading: () =>
            AvatarOrHash(null, message.authorId.substring(1), height: height),
      );
}
