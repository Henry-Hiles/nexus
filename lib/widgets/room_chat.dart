import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:measure_size/measure_size.dart";
import "package:nexus/controllers/account_data_controller.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/power_level_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/controllers/via_controller.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/composer.dart";
import "package:nexus/widgets/emoji_picker_button.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:nexus/widgets/member_list.dart";
import "package:nexus/widgets/room_appbar.dart";
import "package:nexus/widgets/flash_wrapper.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/form_text_input.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/loading.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class RoomChat extends HookConsumerWidget {
  final bool isDesktop;
  final bool showMembersByDefault;
  final String? roomId;
  const RoomChat({
    required this.roomId,
    required this.isDesktop,
    required this.showMembersByDefault,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedEvent = useState<Event?>(null);
    final relationType = useState(RelationType.reply);
    final flashingEvent = useState<String?>(null);

    final composerSize = useState<double>(64);

    final memberListOpened = useState<bool>(showMembersByDefault);

    final userId = ref.watch(ClientStateController.provider)?.userId;
    final theme = Theme.of(context);

    if (userId == null || this.roomId == null) {
      return Scaffold(
        appBar: RoomAppbar(
          roomId: this.roomId,
          isDesktop: isDesktop,
          onOpenDrawer: (_) => Scaffold.of(context).openDrawer(),
          onOpenMemberList: null,
        ),
        body: Center(
          child: Text(
            "Nothing to see here...",
            style: theme.textTheme.headlineMedium,
          ),
        ),
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

    Future<void> loadOlder() async {
      if (controllerData
          case AsyncData(:final value) || AsyncLoading(:final value?)) {
        topEventBeforeLoad.value = value.firstOrNull?.eventId;
        await notifier.loadOlder();
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(
            scrollController.position.maxScrollExtent - .000001,
          );
        }
      });

      return null;
    }, [scrollController.hasClients]);

    useEffect(() {
      if (controllerData case AsyncData(
        :final value,
      ) when scrollController.hasClients) {
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

        final room = ref.watch(
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
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );

    IList<PopupMenuEntry> getEventOptions(Event event) {
      final danger = theme.colorScheme.error;
      final isSentByMe = event.sender == userId;
      return [
        if (ref.watch(
          PowerLevelController.provider(
            .new(eventType: .reaction, roomId: roomId),
          ),
        ))
          PopupMenuItem(
            enabled: false,
            child: IconTheme(
              data: theme.iconTheme,
              child: Row(
                children: [
                  ...{
                        ...ref.watch(
                          AccountDataController.provider.select(
                            (value) => IList(
                              value["m.recent_emoji"]
                                      ?.content["recent_emoji"] ??
                                  [],
                            ).map((entry) => entry["emoji"]).toIList(),
                          ),
                        ),
                        "👍",
                        "🤣",
                        "😭",
                        "🤔",
                      }
                      .toIList()
                      .sublist(0, 4)
                      .map(
                        (emoji) => IconButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await notifier
                                .sendReaction(emoji, event)
                                .onError(showError);
                          },
                          icon: Text(emoji),
                        ),
                      ),
                  EmojiPickerButton(
                    context: context,
                    onPressed: Navigator.of(context).pop,
                    onSelection: (emoji) =>
                        notifier.sendReaction(emoji, event).onError(showError),
                  ),
                ],
              ),
            ),
          ),
        if (ref.watch(
          PowerLevelController.provider(
            PowerLevelConfig(eventType: .message, roomId: roomId),
          ),
        ))
          PopupMenuItem(
            onTap: () {
              relatedEvent.value = event;
              relationType.value = .reply;
              composerNode.requestFocus();
            },
            child: ListTile(leading: Icon(Icons.reply), title: Text("Reply")),
          ),
        if (event.content is MessageContent && isSentByMe)
          PopupMenuItem(
            onTap: () {
              relatedEvent.value = event;
              relationType.value = .edit;
              composerNode.requestFocus();
            },
            child: ListTile(leading: Icon(Icons.edit), title: Text("Edit")),
          ),
        PopupMenuItem(
          onTap: () async {
            final room = ref.watch(
              RoomsController.provider.select((value) => value[roomId]),
            );
            if (room == null) return;

            final vias = ref.watch(ViaController.provider(room));

            await Clipboard.setData(
              ClipboardData(
                text:
                    "matrix:roomid/${room.metadata?.id.substring(1)}/e/${event.eventId}$vias)",
              ),
            );
          },
          child: ListTile(leading: Icon(Icons.link), title: Text("Copy Link")),
        ),
        if (ref.watch(
          PowerLevelController.provider(
            .redaction(targetUser: event.sender, roomId: roomId),
          ),
        ))
          PopupMenuItem(
            onTap: () => showDialog(
              context: context,
              builder: (context) => HookBuilder(
                builder: (_) {
                  final deleteReasonController = useTextEditingController();
                  return AlertDialog(
                    title: Text("Delete Message"),
                    content: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          "Are you sure you want to delete this message? This can not be reversed.",
                        ),
                        SizedBox(height: 12),
                        FormTextInput(
                          required: false,
                          capitalize: true,
                          controller: deleteReasonController,
                          title: "Reason for deletion (optional)",
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await notifier
                              .deleteMessage(
                                event,
                                reason: deleteReasonController.text,
                              )
                              .onError(showError);
                        },
                        child: Text("Delete"),
                      ),
                    ],
                  );
                },
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.delete, color: danger),
              title: Text("Delete", style: .new(color: danger)),
            ),
          ),
        PopupMenuItem(
          onTap: () => showDialog(
            context: context,
            builder: (context) => HookBuilder(
              builder: (_) {
                final reasonController = useTextEditingController();
                return AlertDialog(
                  title: Text("Report"),
                  content: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        "Report this event to your server administrators, who can take action like banning this server or room.",
                      ),

                      SizedBox(height: 12),
                      FormTextInput(
                        required: false,
                        capitalize: true,
                        controller: reasonController,
                        title: "Reason for report (optional)",
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        client.reportEvent(
                          .new(
                            roomId: roomId,
                            eventId: event.eventId,
                            reason: reasonController.text.isEmpty
                                ? null
                                : reasonController.text,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text("Report"),
                    ),
                  ],
                );
              },
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.report, color: danger),
            title: Text("Report", style: .new(color: danger)),
          ),
        ),
      ].toIList();
    }

    return Scaffold(
      appBar: RoomAppbar(
        roomId: roomId,
        isDesktop: isDesktop,
        onOpenDrawer: (_) => Scaffold.of(context).openDrawer(),
        onOpenMemberList: (thisContext) {
          memberListOpened.value = !memberListOpened.value;
          Scaffold.of(thisContext).openEndDrawer();
        },
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: .symmetric(horizontal: 12),
                    child: switch (controllerData) {
                      AsyncData(:final value) ||
                      AsyncLoading(:final value?) => CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: .symmetric(vertical: 36),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: controllerData is AsyncData
                                      ? loadOlder
                                      : null,
                                  child: Text("Load More"),
                                ),
                              ),
                            ),
                          ),

                          SuperSliverList.builder(
                            listController: listController.value,
                            itemCount: value.length,
                            itemBuilder: (_, index) {
                              final event = value[index];
                              final previousEvent = value.getOrNull(index - 1);
                              return FlashWrapper(
                                EventRenderer(
                                  event,
                                  onTapReply: () async {
                                    final replyId = event.replyTo;
                                    listController.value.animateToItem(
                                      index: value.indexWhere(
                                        (element) => element.eventId == replyId,
                                      ),
                                      scrollController: scrollController,
                                      alignment: 0.5,
                                      duration: (_) => .new(milliseconds: 700),
                                      curve: (_) => Curves.easeInOut,
                                    );
                                    flashingEvent.value = replyId;
                                    await Future.delayed(.new(seconds: 1), () {
                                      if (flashingEvent.value == replyId) {
                                        flashingEvent.value = null;
                                      }
                                    });
                                  },
                                  getEventOptions: getEventOptions,
                                  isGrouped:
                                      previousEvent?.content
                                          is MessageContent &&
                                      previousEvent?.redactedBy == null &&
                                      previousEvent?.relationType !=
                                          "m.replace" &&
                                      "${event.sender}${event.pmp?.id}" ==
                                          "${previousEvent?.sender}${previousEvent?.pmp?.id}",
                                ),
                                isFlashing:
                                    flashingEvent.value == event.eventId,
                              );
                            },
                          ),

                          SliverPadding(
                            padding: .only(bottom: composerSize.value),
                          ),
                        ],
                      ),
                      AsyncLoading() => Loading(),
                      AsyncError(:final error, :final stackTrace) =>
                        ErrorDialog(error, stackTrace),
                    },
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
                      onSend: (text, {required shouldMention, required tags}) =>
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

          if (memberListOpened.value == true && showMembersByDefault)
            MemberList(roomId),
        ],
      ),

      endDrawer: showMembersByDefault ? null : MemberList(roomId),
    );
  }
}
