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
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/composer.dart";
import "package:nexus/widgets/pinned_events_drawer.dart";
import "package:nexus/widgets/member_list.dart";
import "package:nexus/widgets/room_appbar.dart";
import "package:nexus/main.dart";
import "package:super_sliver_list/super_sliver_list.dart";
import "package:nexus/widgets/room_chat/chat_timeline.dart";
import "package:nexus/helpers/extensions/build_event_options.dart";

final class const RoomChat({
  required final String? roomId,
  required final bool isDesktop,
  required final bool showMembersByDefault,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedEvent = useState<Event?>(null);
    final relationType = useState(RelationType.reply);
    final highlightedEvent = useState<String?>(null);

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

    final controllerProvider = RoomChatController.provider(roomId);
    final notifier = ref.watch(controllerProvider.notifier);

    final client = ref.watch(ClientController.provider.notifier);

    final listController = useRef(ListController());
    final scrollController = useScrollController();
    final controllerData = ref.watch(controllerProvider);

    final topEventBeforeLoad = useState<String?>(null);
    final hasMore = useState<bool>(true);
    final loadingOlder = useRef(false);

    Future<void> jumpToId(String eventId) async {
      final index =
          controllerData.value?.indexWhere(
            (element) => element.eventId == eventId,
          ) ??
          -1;
      if (index == -1) return;

      listController.value.animateToItem(
        index: index,
        scrollController: scrollController,
        alignment: 0.5,
        duration: (_) => .new(milliseconds: 700),
        curve: (_) => Curves.easeInOut,
      );
      highlightedEvent.value = eventId;
      await Future.delayed(.new(seconds: 1), () {
        if (highlightedEvent.value == eventId) {
          highlightedEvent.value = null;
        }
      });
    }

    Future<void> loadOlder() async {
      if (loadingOlder.value || !hasMore.value) return;
      if (controllerData case AsyncData(:final value?)) {
        loadingOlder.value = true;
        topEventBeforeLoad.value = value.firstOrNull?.eventId;
        try {
          hasMore.value = await notifier.loadOlder();
        } finally {
          loadingOlder.value = false;
        }
      }
    }

    useEffect(() {
      ref
          .read(controllerProvider.future)
          .then(
            (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.jumpTo(
                  scrollController.position.maxScrollExtent - .000001,
                );
              }
            }),
          );

      return null;
    }, [scrollController.hasClients]);

    useEffect(() {
      if (controllerData case AsyncData(:final value?)
          when scrollController.hasClients) {
        if (topEventBeforeLoad.value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              final index = value.indexWhere(
                (event) => event.eventId == topEventBeforeLoad.value,
              );
              if (index != -1) {
                listController.value.jumpToItem(
                  index: index,
                  scrollController: scrollController,
                  alignment: 0,
                );
              }
            }
            topEventBeforeLoad.value = null;
          });
        } else if (scrollController.position.atEdge &&
            scrollController.position.pixels != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.jumpTo(
                scrollController.position.maxScrollExtent,
              );
            }
          });
        }
      }

      return null;
    }, [controllerData]);

    useEffect(() {
      Future<void> listener() async {
        if (!scrollController.hasClients || !scrollController.position.atEdge) {
          return;
        }

        final room = ref.read(
          RoomsController.provider.select((value) => value[roomId]),
        );
        if (room == null) return;

        if (scrollController.position.pixels == 0) {
          if (room.hasMore) {
            await loadOlder();
          }
        } else {
          await client.markRead(room);
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [roomId, controllerData]);

    final composerNode = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == .escape) {
          relatedEvent.value = null;
          return .handled;
        }

        return .ignored;
      },
    );

    IList<PopupMenuEntry> getEventOptions(Event event) =>
        event.buildEventOptions(
          context: context,
          ref: ref,
          roomId: roomId,
          userId: userId,
          onRelation: (event, type) {
            relatedEvent.value = event;
            relationType.value = type;
            composerNode.requestFocus();
          },
        );

    return Scaffold(
      endDrawer: PinnedEventsDrawer(
        roomId,
        getEventOptions: getEventOptions,
        jumpToId: jumpToId,
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
                        child: ChatTimeline(
                          controllerData: controllerData,
                          scrollController: scrollController,
                          listController: listController.value,
                          hasMore: hasMore.value,
                          loadOlder: loadOlder,
                          jumpToId: jumpToId,
                          getEventOptions: getEventOptions,
                          highlightedEvent: highlightedEvent.value,
                          composerHeight: composerSize.value,
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
                                        relation: relatedEvent.value,
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
