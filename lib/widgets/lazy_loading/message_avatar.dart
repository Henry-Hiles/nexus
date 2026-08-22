import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class const MessageAvatar(
  final Event event, {
  final double height = 24,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    AuthorController.provider(event),
  )) {
    AsyncData(:final value) || AsyncLoading(:final value?) => InkWell(
      onTap: () =>
          context.showUserPopover(value, event.sender, roomId: event.roomId),
      child: AvatarOrHash(
        value.avatarUrl,
        value.displayName ?? event.sender.localpart,
        height: height,
      ),
    ),
    _ => AvatarOrHash(null, event.sender.localpart, height: height),
  };
}
