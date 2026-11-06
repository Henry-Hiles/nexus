import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/member_list_opened.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/helpers/hooks/chat_composer.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/pinned_events_drawer.dart";
import "package:nexus/widgets/member_list.dart";
import "package:nexus/widgets/room_appbar.dart";
import "package:nexus/widgets/search_drawer.dart";
import "package:nexus/widgets/sync_status_banner.dart";
import "package:nexus/widgets/thread_drawer.dart";
import "package:nexus/widgets/threads_drawer.dart";
import "package:nexus/widgets/room_chat/chat_body.dart";
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
    final composer = ChatComposer.use();
    final pendingJump = ref.read(JumpRequestController.provider);
    final contextualEvent = useState<int?>(switch (pendingJump) {
      // Threaded events open their thread instead, leaving the timeline
      (:final roomId, :final rowId)
          when roomId == this.roomId &&
              ref
                      .read(RoomsController.provider)[roomId]
                      ?.events[rowId]
                      ?.threadRoot ==
                  null =>
        rowId,
      _ => null,
    });

    final thread = useState<({String root, int? event})?>(null);
    final threadScaffold = useMemoized(GlobalKey<ScaffoldState>.new);

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
          onOpenDrawer: Scaffold.of(context).openDrawer,
        ),
        body: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(child: nothing),
          ],
        ),
      );
    }

    final roomId = this.roomId!;

    final jumpRowId = ref.watch(
      JumpRequestController.provider.select(
        (request) => request?.roomId == roomId ? request?.rowId : null,
      ),
    );

    final ChatParams chat = (
      roomId: roomId,
      contextualEvent: contextualEvent.value,
      threadRoot: null,
    );
    final controllerProvider = RoomChatController.provider(chat);
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

    void openThread(String root, {int? event}) {
      thread.value = (root: root, event: event);

      // The drawer is only there once rebuilt with the thread
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => threadScaffold.currentState?.openEndDrawer(),
      );
    }

    // Threaded events aren't in the timeline, only their thread
    Future<void> jumpToEvent(int rowId) async {
      final threadRoot = ref
          .read(RoomsController.provider)[roomId]
          ?.events[rowId]
          ?.threadRoot;

      if (threadRoot == null) return scroll.jumpToEvent(rowId);
      openThread(threadRoot, event: rowId);
    }

    useEffect(() {
      if (jumpRowId == null) return null;

      void check() {
        if (!context.mounted) return;

        if (scroll.scrollController.hasClients) {
          jumpToEvent(jumpRowId);
          Future.microtask(
            () => ref.read(JumpRequestController.provider.notifier).consume(),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => check());
        }
      }

      check();

      return null;
    }, [jumpRowId]);

    IList<PopupMenuEntry> getEventOptions(Event event) =>
        event.buildEventOptions(
          context: context,
          ref: ref,
          roomId: roomId,
          userId: userId,
          onRelation: composer.relate,
          onStartThread: openThread,
        );

    return Scaffold(
      key: threadScaffold,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: switch (thread.value) {
        (:final root, :final event) => ThreadDrawer(
          roomId,
          threadRoot: root,
          initialEvent: event,
          jumpToRoomEvent: jumpToEvent,
          userId: userId,
          key: ValueKey((roomId, root, event)),
        ),
        null => null,
      },
      body: Scaffold(
        endDrawerEnableOpenDragGesture: false,
        endDrawer: SearchDrawer(
          roomId,
          getEventOptions: getEventOptions,
          jumpToEvent: jumpToEvent,
        ),
        body: Builder(
          builder: (searchContext) => Scaffold(
            endDrawerEnableOpenDragGesture: false,
            endDrawer: ThreadsDrawer(roomId, onOpenThread: openThread),
            body: Builder(
              builder: (threadsContext) => Scaffold(
                endDrawerEnableOpenDragGesture: false,
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
                      onOpenPinnedMessagesList: Scaffold.of(middleContext)
                          .openEndDrawer,
                      onOpenSearch: Scaffold.of(searchContext).openEndDrawer,
                      onOpenThreads: Scaffold.of(threadsContext).openEndDrawer,
                    ),
                    body: Column(
                      children: [
                        const SyncStatusBanner(),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ChatBody(
                                  chat: chat,
                                  scroll: scroll,
                                  jumpToEvent: jumpToEvent,
                                  getEventOptions: getEventOptions,
                                  composer: composer,
                                  onOpenThread: openThread,
                                ),
                              ),

                              if (memberListOpened && showMembersByDefault)
                                MemberList(roomId),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
