import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:measure_size/measure_size.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/tombstone.dart";
import "package:nexus/helpers/hooks/chat_composer.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/main.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/composer/composer.dart";
import "package:nexus/widgets/composer/typing_indicator.dart";
import "package:nexus/widgets/common/error_dialog.dart";
import "package:nexus/widgets/common/loading.dart";
import "package:nexus/widgets/room_chat/chat_timeline.dart";
import "package:nexus/widgets/room_chat/tombstone_banner.dart";

final class const ChatBody({
  required final ChatParams chat,
  required final ChatScroll scroll,
  required final JumpToEvent jumpToEvent,
  required final IList<PopupMenuEntry> Function(Event event) getEventOptions,
  required final ChatComposer composer,
  final void Function(String threadRoot)? onOpenThread,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = chat.roomId;
    final repliedEventRowId = composer.repliedEventRowId;

    final composerSize = useState<double>(64);
    final typingIndicatorSize = useState<double>(0);

    final controllerProvider = RoomChatController.provider(chat);
    final notifier = ref.watch(controllerProvider.notifier);
    final controllerData = ref.watch(controllerProvider);

    final swipeToReply = ref.watch(
      SettingsController.provider.select(
        (settings) => settings.value?.swipeToReply ?? false,
      ),
    );
    final tombstone = ref.watch(TombstoneController.provider(roomId));
    final canReply =
        tombstone == null &&
        ref.watch(
          PowerLevelController.provider(
            .new(eventType: .message, roomId: roomId),
          ),
        );

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: .symmetric(horizontal: 4),
            child: switch (controllerData) {
              AsyncLoading(value: _?) || AsyncData(value: _) => ChatTimeline(
                scroll: scroll,
                jumpToEvent: jumpToEvent,
                chat: chat,
                getEventOptions: getEventOptions,
                onSwipe: swipeToReply && canReply
                    ? (rowId) => composer.relate(rowId, .reply)
                    : null,
                onOpenThread: onOpenThread,
                composerHeight: composerSize.value,
                typingIndicatorHeight: typingIndicatorSize.value,
              ),
              AsyncLoading _ => Loading(),
              AsyncError(:final error, :final stackTrace) => ErrorDialog(
                error,
                stackTrace,
              ),
            },
          ),
        ),
        AnimatedPositioned(
          duration: Durations.short4,
          bottom: composerSize.value,
          left: 12,
          // Leaves room for the jump to bottom button when it's shown
          right: scroll.atBottom ? 12 : 72,
          child: MeasureSize(
            onChange: (size) => typingIndicatorSize.value = size.height,
            child: TypingIndicator(roomId),
          ),
        ),
        Positioned(
          right: 16,
          bottom: composerSize.value,
          child: IgnorePointer(
            ignoring: scroll.atBottom,
            child: AnimatedOpacity(
              opacity: scroll.atBottom ? 0 : 1,
              duration: Durations.short4,
              child: FloatingActionButton.small(
                onPressed: scroll.jumpToBottom,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: MeasureSize(
            onChange: (size) => composerSize.value = size.height,
            child: switch (tombstone) {
              final tombstone? => TombstoneBanner(tombstone),
              null => Composer(
                roomId,
                threadRoot: chat.threadRoot,
                node: composer.node,
                onSend: (text, {required shouldMention, required tags}) =>
                    notifier
                        .send(
                          text,
                          tags: tags,
                          relationType: composer.relationType,
                          shouldMention: shouldMention,
                          relatedEventRowId: composer.relatedEvent,
                        )
                        .onError(showError),
                onSendSticker: (shortcode, image, {required shouldMention}) =>
                    notifier
                        .sendSticker(
                          shortcode,
                          image,
                          shouldMention: shouldMention,
                          repliedEventRowId: repliedEventRowId,
                        )
                        .onError(showError),
                onSendPoll: (poll, {required shouldMention}) => notifier
                    .sendPoll(
                      poll,
                      shouldMention: shouldMention,
                      repliedEventRowId: repliedEventRowId,
                    )
                    .onError(showError),
                onSendLocation: (location, {required shouldMention}) => notifier
                    .sendLocation(
                      location,
                      shouldMention: shouldMention,
                      repliedEventRowId: repliedEventRowId,
                    )
                    .onError(showError),
                onSendBotCommand: (draft) => notifier
                    .sendBotCommand(draft, repliedEventRowId: repliedEventRowId)
                    .onError(showError),
              ),
            },
          ),
        ),
      ],
    );
  }
}
