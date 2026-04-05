import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flyer_chat_file_message/flyer_chat_file_message.dart";
import "package:flyer_chat_system_message/flyer_chat_system_message.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/report_request.dart";
import "package:nexus/widgets/chat_page/composer/chat_box.dart";
import "package:nexus/widgets/chat_page/expandable_image_message.dart";
import "package:nexus/widgets/chat_page/member_list.dart";
import "package:nexus/widgets/chat_page/wrappers/message_wrapper.dart";
import "package:nexus/widgets/chat_page/room_appbar.dart";
import "package:nexus/widgets/chat_page/wrappers/text_message_wrapper.dart";
import "package:nexus/widgets/chat_page/reply_widget.dart";
import "package:nexus/widgets/form_text_input.dart";
import "package:nexus/main.dart";

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
    final relatedMessage = useState<Message?>(null);
    final memberListOpened = useState<bool>(showMembersByDefault);
    final relationType = useState(RelationType.reply);
    final userId = ref.watch(ClientStateController.provider)?.userId;
    final roomId = ref.watch(
      SelectedRoomController.provider.select((value) => value?.metadata?.id),
    );

    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;

    if (roomId == null || userId == null) {
      return Scaffold(
        appBar: RoomAppbar(
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

    final controllerProvider = RoomChatController.provider(roomId);
    final notifier = ref.watch(controllerProvider.notifier);

    final composerNode = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          relatedMessage.value = null;
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );

    List<PopupMenuEntry> getMessageOptions(Message message) {
      final isSentByMe = message.authorId == userId;
      return [
        PopupMenuItem(
          onTap: () {
            relatedMessage.value = message;
            relationType.value = RelationType.reply;
            composerNode.requestFocus();
          },
          child: ListTile(leading: Icon(Icons.reply), title: Text("Reply")),
        ),
        if (message is TextMessage && isSentByMe)
          PopupMenuItem(
            onTap: () {
              relatedMessage.value = message;
              relationType.value = RelationType.edit;
              composerNode.requestFocus();
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
                          Navigator.of(context).pop();
                          await notifier
                              .deleteMessage(
                                message,
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
                        client.reportEvent(
                          ReportRequest(
                            roomId: roomId,
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

    final chatTheme = ChatTheme.fromThemeData(theme).copyWith(
      colors: ChatColors.fromThemeData(theme).copyWith(
        primary: theme.colorScheme.primaryContainer,
        onPrimary: theme.colorScheme.onPrimaryContainer,
      ),
    );

    return Scaffold(
      appBar: RoomAppbar(
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
                          theme: chatTheme,
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
                          builders: Builders(
                            loadMoreBuilder: (_) => SizedBox.shrink(),

                            chatAnimatedListBuilder: (_, itemBuilder) =>
                                ChatAnimatedList(
                                  itemBuilder: itemBuilder,
                                  onEndReached:
                                      ref.watch(
                                        SelectedRoomController.provider.select(
                                          (room) => room?.hasMore == true,
                                        ),
                                      )
                                      ? notifier.loadOlder
                                      : null,
                                  onStartReached: () async {
                                    final room = ref.watch(
                                      SelectedRoomController.provider,
                                    );
                                    return room == null
                                        ? null
                                        : await client.markRead(room);
                                  },
                                  bottomPadding: 72,
                                ),

                            composerBuilder: (_) => ChatBox(
                              node: composerNode,
                              onSend:
                                  (
                                    text, {
                                    required shouldMention,
                                    required tags,
                                  }) => notifier.send(
                                    text,
                                    tags: tags,
                                    relationType: relationType.value,
                                    shouldMention: shouldMention,
                                    relation: relatedMessage.value,
                                  ),
                              relationType: relationType.value,
                              relatedMessage: relatedMessage.value,
                              onDismiss: () => relatedMessage.value = null,
                            ),

                            textMessageBuilder:
                                (
                                  context,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => TextMessageWrapper(
                                  message,
                                  content: message.text,
                                  groupStatus: groupStatus,
                                  onTapReply: notifier.scrollToMessage,
                                  updateMessage: controller.updateMessage,
                                  isSentByMe: isSentByMe,
                                ),

                            imageMessageBuilder:
                                (
                                  context,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => TextMessageWrapper(
                                  message,
                                  content: message.text,
                                  groupStatus: groupStatus,
                                  onTapReply: notifier.scrollToMessage,
                                  updateMessage: controller.updateMessage,
                                  isSentByMe: isSentByMe,
                                  extra: ExpandableImageMessage(
                                    message,
                                    index: index,
                                  ),
                                ),

                            fileMessageBuilder:
                                (
                                  _,
                                  message,
                                  index, {
                                  required bool isSentByMe,
                                  MessageGroupStatus? groupStatus,
                                }) => MessageWrapper(
                                  message,
                                  InkWell(
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Text(
                                          "TODO: Download Attachments",
                                        ),
                                      ),
                                    ),
                                    child: FlyerChatFileMessage(
                                      topWidget: ReplyWidget(
                                        message,
                                        onTapReply: notifier.scrollToMessage,
                                        groupStatus: groupStatus,
                                      ),
                                      message: message,
                                      index: index,
                                    ),
                                  ),
                                  groupStatus,
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
                          resolveUser: (_) async => null,
                          chatController: controller,
                        ),
                      ),
                ),
              ],
            ),
          ),

          if (memberListOpened.value == true && showMembersByDefault)
            MemberList(),
        ],
      ),

      endDrawer: showMembersByDefault ? null : MemberList(),
    );
  }
}
