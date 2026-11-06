import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/build_event_options.dart";
import "package:nexus/helpers/hooks/chat_composer.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/widgets/room_chat/chat_body.dart";

/// The thread from [threadRoot], with a composer to send to it.
final class const ThreadDrawer(
  final String roomId, {
  required final String threadRoot,

  /// An event in the thread to scroll to once it loads.
  final int? initialEvent,
  required final String userId,

  /// Jumps to events outside this thread, like ones replied to from it.
  required final JumpToEvent jumpToRoomEvent,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composer = ChatComposer.use();
    final contextualEvent = useState(initialEvent);

    final ChatParams chat = (
      roomId: roomId,
      contextualEvent: contextualEvent.value,
      threadRoot: threadRoot,
    );
    final controllerProvider = RoomChatController.provider(chat);
    final controllerData = ref.watch(controllerProvider);

    final scroll = ChatScroll.use(
      controllerData: controllerData,
      paginate: ref.watch(controllerProvider.notifier).paginate,
      contextualEvent: contextualEvent,
      markRead: () async {
        final room = ref.read(
          RoomsController.provider.select((rooms) => rooms[roomId]),
        );

        if (room != null) {
          await ref
              .read(ClientController.provider.notifier)
              .markRead(room, threadRoot: threadRoot);
        }
      },
    );

    final initialEventLoaded =
        controllerData.value?.timeline.contains(initialEvent) ?? false;
    // Only once, so returning to the newest events doesn't jump back to it
    final jumpedToInitialEvent = useRef(false);
    useEffect(() {
      if (initialEvent case final rowId?
          when initialEventLoaded && !jumpedToInitialEvent.value) {
        jumpedToInitialEvent.value = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => scroll.jumpToEvent(rowId),
        );
      }

      return null;
    }, [initialEventLoaded]);

    // This chat only has the thread, so other events are left to the room.
    // Ones in the thread that aren't loaded are loaded around, like the room.
    Future<void> jumpToEvent(int rowId) async {
      final isInThread =
          ref
              .read(RoomsController.provider)[roomId]
              ?.events[rowId]
              ?.threadRoot ==
          threadRoot;
      if (isInThread ||
          (controllerData.value?.timeline.contains(rowId) ?? false)) {
        return scroll.jumpToEvent(rowId);
      }

      Scaffold.of(context).closeEndDrawer();
      await jumpToRoomEvent(rowId);
    }

    return Drawer(
      width: 400,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: Icon(Icons.forum),
          title: Text("Thread"),
          actionsPadding: .only(right: 4),
          actions: [
            IconButton(
              onPressed: Scaffold.of(context).closeEndDrawer,
              icon: Icon(Icons.close),
              tooltip: "Close thread",
            ),
          ],
        ),
        body: ChatBody(
          chat: chat,
          scroll: scroll,
          jumpToEvent: jumpToEvent,
          getEventOptions: (event) => event.buildEventOptions(
            context: context,
            ref: ref,
            roomId: roomId,
            userId: userId,
            onRelation: composer.relate,
          ),
          composer: composer,
        ),
      ),
    );
  }
}
