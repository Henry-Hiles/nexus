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
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
import "package:nexus/widgets/chat_page/chat_box.dart";
import "package:nexus/widgets/chat_page/html/html.dart";
import "package:nexus/widgets/chat_page/member_list.dart";
import "package:nexus/widgets/chat_page/room_appbar.dart";
import "package:nexus/widgets/chat_page/top_widget.dart";
import "package:nexus/widgets/form_text_input.dart";
import "package:nexus/widgets/loading.dart";

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
    final replyToMessage = useState<Message?>(null);
    final memberListOpened = useState<bool>(showMembersByDefault);
    final theme = Theme.of(context);

    return ref
        .watch(SelectedRoomController.provider)
        .betterWhen(
          data: (room) {
            if (room == null) {
              return Center(
                child: Text(
                  "Nothing to see here...",
                  style: theme.textTheme.headlineMedium,
                ),
              );
            }
            final controllerProvider = RoomChatController.provider(
              room.roomData,
            );
            final notifier = ref.watch(controllerProvider.notifier);

            List<PopupMenuEntry> getMessageOptions(Message message) => [
              PopupMenuItem(
                onTap: () => replyToMessage.value = message,
                child: ListTile(
                  leading: Icon(Icons.reply),
                  title: Text("Reply"),
                ),
              ),
              if (message.authorId == room.roomData.client.userID)
                PopupMenuItem(
                  onTap: () {},
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text("Edit"),
                  ),
                ),
              if (message.authorId == room.roomData.client.userID ||
                  room.roomData.canRedact)
                PopupMenuItem(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => HookBuilder(
                      builder: (_) {
                        final deleteReasonController =
                            useTextEditingController();
                        return AlertDialog(
                          title: Text("Delete Message"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
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
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text("Delete"),
                  ),
                ),
            ];

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
                    child: ref
                        .watch(controllerProvider)
                        .betterWhen(
                          data: (controller) => Chat(
                            currentUserId: room.roomData.client.userID!,
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
                                  required details,
                                  required index,
                                }) => context.showContextMenu(
                                  globalPosition: details.globalPosition,
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
                              loadMoreBuilder: (_) => Loading(),
                              chatAnimatedListBuilder: (_, itemBuilder) =>
                                  ChatAnimatedList(
                                    itemBuilder: itemBuilder,
                                    onEndReached: notifier.loadOlder,
                                    onStartReached: notifier.markRead,
                                  ),
                              composerBuilder: (_) => ChatBox(
                                replyToMessage: replyToMessage.value,
                                onDismiss: () => replyToMessage.value = null,
                                room: room.roomData,
                              ),
                              textMessageBuilder:
                                  (
                                    context,
                                    message,
                                    index, {
                                    required bool isSentByMe,
                                    MessageGroupStatus? groupStatus,
                                  }) => FlyerChatTextMessage(
                                    customWidget: Html(
                                      message.metadata?["formatted"]
                                              .replaceAllMapped(
                                                RegExp(
                                                  regexLink,
                                                  caseSensitive: false,
                                                ),
                                                (m) =>
                                                    "<a href=\"${m.group(0)!}\">${m.group(0)!}</a>",
                                              ) +
                                          ((message.editedAt != null)
                                              ? "<sub edited>(edited)</sub>"
                                              : ""),
                                      client: room.roomData.client,
                                    ),
                                    topWidget: TopWidget(
                                      message,
                                      headers: room.roomData.client.headers,
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
                                    onLinkPreviewDataFetched:
                                        (linkPreviewData) =>
                                            notifier.updateMessage(
                                              message,
                                              message.copyWith(
                                                linkPreviewData:
                                                    linkPreviewData,
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
                                      headers: room.roomData.client.headers,
                                      groupStatus: groupStatus,
                                      alwaysShow: true,
                                    ),
                                    message: message,
                                    index: index,
                                    headers: room.roomData.client.headers,
                                  ),
                              fileMessageBuilder:
                                  (
                                    _,
                                    message,
                                    index, {
                                    required bool isSentByMe,
                                    MessageGroupStatus? groupStatus,
                                  }) => InkWell(
                                    onTap: () => showAboutDialog(
                                      context: context,
                                    ), // TODO: Download
                                    child: FlyerChatFileMessage(
                                      topWidget: TopWidget(
                                        message,
                                        headers: room.roomData.client.headers,
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

                  if (memberListOpened.value == true && showMembersByDefault)
                    MemberList(room.roomData),
                ],
              ),
              endDrawer: showMembersByDefault
                  ? null
                  : MemberList(room.roomData),
            );
          },
        );
  }
}
