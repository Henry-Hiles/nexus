import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/author.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/content/membership.dart";

class const MessageDisplayname(
  final Event event, {
  final TextStyle? style,
  final bool clickable = true,
  final bool shouldWrap = true,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    AuthorController.provider(event),
  )) {
    AsyncData(:final MembershipContent? value) ||
    AsyncLoading(:final value) ||
    AsyncError(:final value) => InkWell(
      onTap: clickable && value != null
          ? () => context.showUserPopover(
              value,
              event.sender,
              roomId: event.roomId,
            )
          : null,
      child: switch ([
        Text(
          value?.displayName ?? event.sender.localpart,
          style:
              style ?? .new(color: event.sender.colorHash, fontWeight: .bold),
          maxLines: 1,
          overflow: .ellipsis,
        ),
        if (event.pmp != null)
          Text(
            "(via ${event.sender})",
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: event.sender.colorHash, fontWeight: .bold),
            maxLines: 1,
            overflow: .ellipsis,
          ),
      ]) {
        final children when shouldWrap => Wrap(
          spacing: 4,
          crossAxisAlignment: .center,
          children: children,
        ),
        final children => Row(
          spacing: 4,
          mainAxisSize: .min,
          children: [for (final child in children) Flexible(child: child)],
        ),
      },
    ),
  };
}
