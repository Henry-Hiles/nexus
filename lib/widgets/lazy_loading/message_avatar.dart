import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author_controller.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MessageAvatar extends ConsumerWidget {
  final Event event;
  final double height;
  const MessageAvatar(this.event, {this.height = 24, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(AuthorController.provider(event))) {
        AsyncData(:final value) || AsyncLoading(:final value?) => InkWell(
          onTapUp: (details) => context.showUserPopover(
            value,
            event.sender,
            roomId: event.roomId,
            globalPosition: details.globalPosition,
          ),
          child: AvatarOrHash(
            value.avatarUrl,
            value.displayName ?? event.sender.localpart,
            height: height,
          ),
        ),
        _ => AvatarOrHash(null, event.sender.localpart, height: height),
      };
}
