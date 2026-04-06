import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";

class MessageDisplayname extends ConsumerWidget {
  final Message message;
  final TextStyle? style;
  final bool clickable;
  const MessageDisplayname(
    this.message, {
    this.clickable = true,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(AuthorController.provider(message))
      .betterWhen(
        data: (membership) => InkWell(
          onTapUp: clickable
              ? (details) => context.showUserPopover(
                  membership,
                  globalPosition: details.globalPosition,
                )
              : null,
          child: Text(
            "${membership.displayName}${message.metadata?["pmp"] == null ? "" : " (via ${message.authorId})"}",
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        loading: () => Text(""),
      );
}
