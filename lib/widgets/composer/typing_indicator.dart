import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_typing.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/hooks/tap_recognizer.dart";
import "package:nexus/widgets/bouncing_dots.dart";
import "package:nexus/widgets/user_span.dart";

class const TypingIndicator(final String roomId, {super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typing = ref.watch(RoomTypingController.provider(roomId));

    // Past three people, only the first two are named
    final named = typing.length > 3 ? 2 : typing.length;
    // One for each person who can be named
    final recognizers = [
      useTapRecognizer(),
      useTapRecognizer(),
      useTapRecognizer(),
    ];
    final subjects = [
      ...typing
          .take(named)
          .mapIndexed(
            (index, typingUserId) => UserSpan(
              context,
              ref
                      .watch(
                        UserController.provider(
                          .new(roomId: roomId, userId: typingUserId),
                        ),
                      )
                      .value
                      ?.displayName ??
                  typingUserId.localpart,
              userId: typingUserId,
              roomId: roomId,
              recognizer: recognizers[index],
              style: TextStyle(fontWeight: .bold),
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
