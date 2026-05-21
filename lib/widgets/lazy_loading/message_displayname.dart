import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/event.dart";

class MessageDisplayname extends ConsumerWidget {
  final Event event;
  final TextStyle? style;
  final bool clickable;
  const MessageDisplayname(
    this.event, {
    this.clickable = true,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(AuthorController.provider(event))
      .betterWhen(
        data: (membership) => InkWell(
          onTapUp: clickable
              ? (details) => context.showUserPopover(
                  membership,
                  event.sender,
                  globalPosition: details.globalPosition,
                )
              : null,
          child: Text(
            "${membership.displayName ?? event.sender.localpart}${event.pmp == null ? "" : " (via ${event.sender})"}",
            style:
                style ??
                TextStyle(
                  color: event.sender.colorHash,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        loading: () => Text(""),
      );
}
