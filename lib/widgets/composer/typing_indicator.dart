import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_typing.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/widgets/bouncing_dots.dart";

class const TypingIndicator(final String roomId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typing = ref.watch(RoomTypingController.provider(roomId));

    // Past three people, only the first two are named
    final named = typing.length > 3 ? 2 : typing.length;
    final subjects = [
      ...typing
          .take(named)
          .map(
            (typingUserId) => WidgetSpan(
              alignment: .baseline,
              baseline: .alphabetic,
              child: Builder(
                builder: (context) => InkWell(
                  onTap: () =>
                      context.showUserPopover(typingUserId, roomId: roomId),
                  child: Text(
                    ref
                            .watch(
                              UserController.provider(
                                .new(roomId: roomId, userId: typingUserId),
                              ),
                            )
                            .value
                            ?.displayName ??
                        typingUserId.localpart,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: .bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      if (typing.length > named)
        TextSpan(text: "${typing.length - named} others"),
    ];

    final spans = [
      ...subjects.expandIndexed(
        (index, subject) => [
          if (index > 0)
            TextSpan(
              text: index < subjects.length - 1
                  ? ", "
                  : subjects.length > 2
                  ? ", and "
                  : " and ",
            ),
          subject,
        ],
      ),
      TextSpan(text: subjects.length == 1 ? " is typing..." : " are typing..."),
    ];

    return AnimatedSwitcher(
      duration: Durations.medium2,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation,
          alignment: .bottomLeft,
          child: child,
        ),
      ),
      child: typing.isEmpty
          ? const SizedBox.shrink()
          : Align(
              alignment: .bottomLeft,
              child: Material(
                color: theme.colorScheme.surfaceContainerHigh,
                elevation: 1,
                shape: const StadiumBorder(),
                child: Padding(
                  padding: .symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisSize: .min,
                    spacing: 8,
                    children: [
                      BouncingDots(color: theme.colorScheme.onSurfaceVariant),
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: spans),
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
