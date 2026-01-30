import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_link_previewer/flutter_link_previewer.dart";
import "package:flyer_chat_file_message/flyer_chat_file_message.dart";
import "package:flyer_chat_image_message/flyer_chat_image_message.dart";
import "package:flyer_chat_system_message/flyer_chat_system_message.dart";
import "package:flyer_chat_text_message/flyer_chat_text_message.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/report_request.dart";
import "package:nexus/widgets/chat_page/chat_box.dart";
import "package:nexus/widgets/chat_page/html/html.dart";
import "package:nexus/widgets/chat_page/member_list.dart";
import "package:nexus/widgets/chat_page/room_appbar.dart";
import "package:nexus/widgets/chat_page/top_widget.dart";
import "package:nexus/widgets/form_text_input.dart";
import "package:nexus/widgets/loading.dart";
// import "package:dynamic_polls/dynamic_polls.dart";

class RoomChat extends HookConsumerWidget {
  final bool isDesktop;
  final bool showMembersByDefault;
  const RoomChat({
    required this.isDesktop,
    required this.showMembersByDefault,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(ClientController.provider.notifier);
    final replyToMessage = useState<Message?>(null);
    final memberListOpened = useState<bool>(showMembersByDefault);
    final relationType = useState(RelationType.reply);
    final room = ref.watch(SelectedRoomController.provider);
    final userId = ref.watch(ClientStateController.provider)?.userId;

    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;

    if (room == null || userId == null || room.metadata?.id == null) {
      return Center(
        child: Text(
          "Nothing to see here...",
          style: theme.textTheme.headlineMedium,
        ),
      );
    }

    final controllerProvider = RoomChatController.provider(room.metadata!.id);
    final notifier = ref.watch(controllerProvider.notifier);

    List<PopupMenuEntry> getMessageOptions(Message message) {
      final isSentByMe = message.authorId == userId;
      return [
        PopupMenuItem(
          onTap: () {
            replyToMessage.value = message;
            relationType.value = RelationType.reply;
          },
          child: ListTile(leading: Icon(Icons.reply), title: Text("Reply")),
        ),
        if (message is TextMessage && isSentByMe)
          PopupMenuItem(
            onTap: () {
              replyToMessage.value = message;
              relationType.value = RelationType.edit;
            },
            child: ListTile(leading: Icon(Icons.edit), title: Text("Edit")),
          ),
        if (isSentByMe) // TODO: Or if user has permission to redact others' messages
          PopupMenuItem(
            onTap: () => showDialog(
              context: context,
              builder: (context) => HookBuilder(
                builder: (_) {
                  final deleteReasonController = useTextEditingController();
                  return AlertDialog(
                    title: Text("Delete Message"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          notifier.deleteMessage(
                            message,
                            reason: deleteReasonController.text,
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text("Delete"),
                      ),
                    ],
                  );
                },
              ),
            ),
            child: ListTile(leading: Icon(Icons.delete), title: Text("Delete")),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (room.metadata == null) return;
                        client.reportEvent(
                          ReportRequest(
                            roomId: room.metadata!.id,
                            eventId: message.id,
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
            title: Text("Report", style: TextStyle(color: danger)),
          ),
        ),
      ];
    }

    return Scaffold(
      appBar: RoomAppbar(
        room,
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
            child: Column(
              children: [
                Expanded(
                  child: ref
                      .watch(controllerProvider)
                      .betterWhen(
                        data: (controller) => Chat(
                          currentUserId: userId,
                          theme: ChatTheme.fromThemeData(theme).copyWith(
                            colors: ChatColors.fromThemeData(theme).copyWith(
                              primary: theme.colorScheme.primaryContainer,
                              onPrimary: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          onMessageSecondaryTap:
                              (
                                context,
                                message, {
                                required index,
                                TapUpDetails? details,
                              }) => details?.globalPosition == null
                              ? null
                              : context.showContextMenu(
                                  globalPosition: details!.globalPosition,
                                  children: getMessageOptions(message),
                                ),
                          onMessageLongPress:
                              (
                                context,
                                message, {
                                required details,
                                required index,
                              }) => context.showContextMenu(
                                globalPosition: details.globalPosition,
                                children: getMessageOptions(message),
                              ),
                          onMessageTap:
                              (
                                context,
                                message, {
                                required details,
                                required index,
                              }) {
                                if (message is ImageMessage) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: EdgeInsets.all(64),
                                      child: InteractiveViewer(
                                        child: Image(
                                          image: CachedNetworkImage(
                                            message.source,
                                            ref.watch(
                                              CrossCacheController.provider,
                                            ),
                                            headers: ref.headers,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                          builders: Builders(
                            loadMoreBuilder: (_) => Loading(),
                            chatAnimatedListBuilder: (_, itemBuilder) =>
                                ChatAnimatedList(
                                  itemBuilder: itemBuilder,
                                  onEndReached: notifier.loadOlder,
                                  onStartReached: () => client.markRead(room),
                                  bottomPadding: 72,
                                ),
                            composerBuilder: (_) => ChatBox(
                              relationType: relationType.value,
                              relatedMessage: replyToMessage.value,
                              onDismiss: () => replyToMessage.value = null,
                              room: room,
                            ),

                            // TODO: Polls
                            // customMessageBuilder:
                            //     (
                            //       context,
                            //       message,
                            //       index, {
                            //       required bool isSentByMe,
                            //       MessageGroupStatus? groupStatus,
                            //     }) {
                            //       final poll =
                            //           message.metadata?["poll"]
                            //               as PollStartContent;
                            //       final responses =
                            //           (message.metadata?["responses"]
                            //                   as Map<
                            //                     String,
                            //                     Set<String>
                            //                   >)
                            //               .values
                            //               .expand((set) => set)
                            //               .fold(<String, int>{}, (
                            //                 acc,
                            //                 value,
                            //               ) {
                            //                 acc[value] =
                            //                     (acc[value] ?? 0) + 1;
                            //                 return acc;
                            //               });

                            //       return Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         spacing: 4,
                            //         children: [
                            //           TopWidget(
                            //             message,
                            //             headers: room
                            //                 .roomData
                            //                 .client
                            //                 .headers,
                            //             groupStatus: groupStatus,
                            //           ),

                            //           DynamicPolls(
                            //             startDate: DateTime.now(),
                            //             endDate: DateTime.now(),
                            //             private:
                            //                 poll.kind ==
                            //                 PollKind.undisclosed,
                            //             allowReselection: true,
                            //             backgroundDecoration:
                            //                 BoxDecoration(
                            //                   borderRadius:
                            //                       BorderRadius.all(
                            //                         Radius.circular(16),
                            //                       ),
                            //                   border: Border.all(
                            //                     color: theme
                            //                         .colorScheme
                            //                         .primaryContainer,
                            //                     width: 4,
                            //                   ),
                            //                 ),
                            //             allStyle: Styles(
                            //               titleStyle: TitleStyle(
                            //                 style: theme
                            //                     .textTheme
                            //                     .headlineSmall,
                            //               ),
                            //               optionStyle: OptionStyle(
                            //                 fillColor: theme
                            //                     .colorScheme
                            //                     .primaryContainer,
                            //                 selectedBorderColor: theme
                            //                     .colorScheme
                            //                     .primary,
                            //                 borderColor: theme
                            //                     .colorScheme
                            //                     .primary,
                            //                 unselectedBorderColor:
                            //                     Colors.transparent,
                            //                 textSelectColor: theme
                            //                     .colorScheme
                            //                     .primary,
                            //               ),
                            //             ),
                            //             onOptionSelected:
                            //                 (int index) {},
                            //             title: poll.question.mText,
                            //             options: poll.answers
                            //                 .map(
                            //                   (option) => option.mText,
                            //                 )
                            //                 .toList(),
                            //           ),
                            //         ],
                            //       );
                            //     },
                            textMessageBuilder:
                                (
                                  context,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => FlyerChatTextMessage(
                                  customWidget: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Html(
                                        (message.metadata?["formatted"]
                                                as String)
                                            .replaceAllMapped(
                                              RegExp(
                                                "(<a\\b[^>]*>.*?<\\/a>)|(\\bhttps?:\\/\\/[^\\s<]+)",
                                                caseSensitive: false,
                                              ),
                                              (m) {
                                                // If it's already an <a> tag, leave it unchanged
                                                if (m.group(1) != null) {
                                                  return m.group(1)!;
                                                }

                                                // Otherwise, wrap the bare URL
                                                final url = m.group(2)!;
                                                return "<a href=\"$url\">$url</a>";
                                              },
                                            )
                                            .replaceAll("\n", "<br/>"),
                                      ),
                                      if (message.editedAt != null)
                                        Text(
                                          "(edited)",
                                          style: theme.textTheme.labelSmall,
                                        ),
                                    ],
                                  ),
                                  topWidget: TopWidget(
                                    message,
                                    groupStatus: groupStatus,
                                  ),
                                  message: message,
                                  showTime: true,
                                  index: index,
                                ),
                            linkPreviewBuilder: (_, message, isSentByMe) =>
                                LinkPreview(
                                  text: message.text,
                                  backgroundColor: isSentByMe
                                      ? theme.colorScheme.inversePrimary
                                      : theme.colorScheme.surfaceContainerLow,
                                  insidePadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  linkPreviewData: message.linkPreviewData,
                                  onLinkPreviewDataFetched: (linkPreviewData) =>
                                      notifier.updateMessage(
                                        message,
                                        message.copyWith(
                                          linkPreviewData: linkPreviewData,
                                        ),
                                      ),
                                ),
                            imageMessageBuilder:
                                (
                                  _,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => FlyerChatImageMessage(
                                  topWidget: TopWidget(
                                    message,
                                    groupStatus: groupStatus,
                                    alwaysShow: true,
                                  ),
                                  customImageProvider: CachedNetworkImage(
                                    message.source,
                                    ref.watch(CrossCacheController.provider),
                                    headers: ref.headers,
                                  ),
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          "Image Failed to Load",
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                  message: message,
                                  index: index,
                                ),
                            fileMessageBuilder:
                                (
                                  _,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Text(
                                        "TODO: Download Attachments", // TODO
                                      ),
                                    ),
                                  ),
                                  child: FlyerChatFileMessage(
                                    topWidget: TopWidget(
                                      message,
                                      groupStatus: groupStatus,
                                    ),
                                    message: message,
                                    index: index,
                                  ),
                                ),
                            systemMessageBuilder:
                                (
                                  _,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => FlyerChatSystemMessage(
                                  message: message,
                                  index: index,
                                ),
                            unsupportedMessageBuilder:
                                (
                                  _,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => Text(
                                  "${message.authorId} sent ${message.metadata?["eventType"]}",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                          resolveUser: notifier.resolveUser,
                          chatController: controller,
                        ),
                      ),
                ),
              ],
            ),
          ),

          if (memberListOpened.value == true && showMembersByDefault)
            MemberList(room),
        ],
      ),

      endDrawer: showMembersByDefault ? null : MemberList(room),
    );
  }
}
