import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:measure_size/measure_size.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/member_list_opened.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/composer.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/pinned_events_drawer.dart";
import "package:nexus/widgets/member_list.dart";
import "package:nexus/widgets/room_appbar.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/room_chat/chat_timeline.dart";
import "package:nexus/helpers/extensions/build_event_options.dart";
import "package:nexus/controllers/jump_request.dart";

final class const RoomChat({
  required final String? roomId,
  required final bool isDesktop,
  required final bool showMembersByDefault,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedEvent = useState<int?>(null);
    final relationType = useState(RelationType.reply);
    final pendingJump = ref.read(JumpRequestController.provider);
    final contextualEvent = useState<int?>(
      pendingJump != null && pendingJump.roomId == this.roomId
          ? pendingJump.rowId
          : null,
    );
    final highlightedEvent = useState<int?>(null);

    final composerSize = useState<double>(64);

    final userId = ref.watch(ClientStateController.provider)?.userId;
    final memberListOpened = ref
        .watch(MemberListOpenedController.provider)
        .requireValue;
    final theme = Theme.of(context);

    final nothing = Center(
      child: Text(
        "Nothing to see here...",
        style: theme.textTheme.headlineMedium,
      ),
    );
    if (userId == null || this.roomId == null) {
      return Scaffold(
        appBar: RoomAppbar(
          roomId: this.roomId,
          isDesktop: isDesktop,
          onOpenDrawer: () => Scaffold.of(context).openDrawer(),
        ),
        body: nothing,
      );
    }

    final roomId = this.roomId!;

    final controllerProvider = RoomChatController.provider((
      roomId: roomId,
      contextualEvent: contextualEvent.value,
    ));
    final notifier = ref.watch(controllerProvider.notifier);

    final client = ref.read(ClientController.provider.notifier);

    final controllerData = ref.watch(controllerProvider);

    final scroll = ChatScroll.use(
      controllerData: controllerData,
      paginate: notifier.paginate,
      contextualEvent: contextualEvent,
      markRead: () async {
        final room = ref.read(
          RoomsController.provider.select((rooms) => rooms[roomId]),
        );

        if (room != null) {
          await client.markRead(room);
        }
      },
    );

    final composerNode = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == .escape) {
          relatedEvent.value = null;
          return .handled;
        }

        return .ignored;
      },
    );

    Future<void> jumpToEvent(int rowId) async {
      highlightedEvent.value = rowId;

      await scroll.jumpToEvent(rowId);
      await Future.delayed(.new(milliseconds: 700), () {
        if (highlightedEvent.value == rowId) {
          highlightedEvent.value = null;
        }
      });
    }

    ref.listen(JumpRequestController.provider, (_, request) {
      if (request == null || request.roomId != roomId) return;

      void tryJump() {
        if (!context.mounted) return;
        if (ref.read(JumpRequestController.provider) != request) return;

        if (scroll.scrollController.hasClients) {
          ref.read(JumpRequestController.provider.notifier).consume();
          jumpToEvent(request.rowId);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => tryJump());
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => tryJump());
    });

    IList<PopupMenuEntry> getEventOptions(Event event) =>
        event.buildEventOptions(
          context: context,
          ref: ref,
          roomId: roomId,
          userId: userId,
          onRelation: (rowId, type) {
            relatedEvent.value = rowId;
            relationType.value = type;
            composerNode.requestFocus();
          },
        );

    return Scaffold(
      endDrawer: PinnedEventsDrawer(
        roomId,
        getEventOptions: getEventOptions,
        jumpToEvent: jumpToEvent,
      ),
      body: Builder(
        builder: (middleContext) => Scaffold(
          endDrawer: showMembersByDefault ? null : MemberList(roomId),
          appBar: RoomAppbar(
            roomId: roomId,
            isDesktop: isDesktop,
            onOpenDrawer: Scaffold.of(context).openDrawer,
            onOpenMemberList: (thisContext) {
              ref
                  .read(MemberListOpenedController.provider.notifier)
                  .set(!memberListOpened);
              Scaffold.of(thisContext).openEndDrawer();
            },
            onOpenPinnedMessagesList: Scaffold.of(middleContext).openEndDrawer,
          ),
          body: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: .symmetric(horizontal: 4),
                        child: switch (controllerData) {
                          AsyncLoading(value: _?) ||
                          AsyncData(value: _) => ChatTimeline(
                            scroll: scroll,
                            roomId: roomId,
                            jumpToEvent: jumpToEvent,
                            getEventOptions: getEventOptions,
                            highlightedEvent: highlightedEvent.value,
                            composerHeight: composerSize.value,
                          ),
                          AsyncLoading _ => Loading(),
                          AsyncError(:final error, :final stackTrace) =>
                            ErrorDialog(error, stackTrace),
                        },
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: composerSize.value,
                      child: IgnorePointer(
                        ignoring: scroll.atBottom,
                        child: AnimatedOpacity(
                          opacity: scroll.atBottom ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
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
                        child: Composer(
                          roomId,
                          node: composerNode,
                          onSend:
                              (text, {required shouldMention, required tags}) =>
                                  notifier
                                      .send(
                                        text,
                                        tags: tags,
                                        relationType: relationType.value,
                                        shouldMention: shouldMention,
                                        relatedEventRowId: relatedEvent.value,
                                      )
                                      .onError(showError),
                          relationType: relationType.value,
                          relatedEvent: relatedEvent.value,
                          onDismiss: () => relatedEvent.value = null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (memberListOpened == true && showMembersByDefault)
                MemberList(roomId),
            ],
          ),
        ),
      ),
    );
  }
}
