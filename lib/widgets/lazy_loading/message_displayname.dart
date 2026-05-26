import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author_controller.dart";
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
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(AuthorController.provider(event))) {
        AsyncData(:final value) || AsyncLoading(:final value?) => InkWell(
          onTapUp: clickable
              ? (details) => context.showUserPopover(
                  value,
                  event.sender,
                  globalPosition: details.globalPosition,
                )
              : null,
          child: Wrap(
            spacing: 4,
            children: [
              Text(
                value.displayName ?? event.sender.localpart,
                style:
                    style ??
                    TextStyle(
                      color: event.sender.colorHash,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (event.pmp != null)
                Text(
                  "(via ${event.sender})",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: event.sender.colorHash,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        _ => Text(""),
      };
}
