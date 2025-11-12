import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_link_previewer/flutter_link_previewer.dart";
import "package:flyer_chat_file_message/flyer_chat_file_message.dart";
import "package:flyer_chat_image_message/flyer_chat_image_message.dart";
import "package:flyer_chat_system_message/flyer_chat_system_message.dart";
import "package:flyer_chat_text_message/flyer_chat_text_message.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/current_room_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/helpers/launch_helper.dart";

class RoomChat extends HookConsumerWidget {
  final bool isDesktop;
  const RoomChat({required this.isDesktop, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlRegex = RegExp(r"https?://[^\s\]\(\)]+");
    final theme = Theme.of(context);
    return ref
        .watch(CurrentRoomController.provider)
        .betterWhen(
          data: (room) {
            final controllerProvider = RoomChatController.provider(
              room.roomData,
            );
            final headers = {
              "authorization": "Bearer ${room.roomData.client.accessToken}",
            };
            return Scaffold(
              appBar: AppBar(
                leading: isDesktop
                    ? null
                    : DrawerButton(onPressed: Scaffold.of(context).openDrawer),
                actionsPadding: EdgeInsets.symmetric(horizontal: 8),
                title: Text(room.title),
                actions: [
                  if (!(Platform.isAndroid || Platform.isIOS))
                    IconButton(
                      onPressed: () => exit(0),
                      icon: Icon(Icons.close),
                    ),
                ],
              ),
              body: ref
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
                      builders: Builders(
                        composerBuilder: (_) => Composer(
                          sendIconColor: theme.colorScheme.primary,
                          sendOnEnter: true,
                          autofocus: true,
                        ),
                        unsupportedMessageBuilder:
                            (
                              _,
                              message,
                              index, {
                              required bool isSentByMe,
                              MessageGroupStatus? groupStatus,
                            }) => kDebugMode
                            ? FlyerChatTextMessage(
                                message: TextMessage(
                                  id: message.id,
                                  authorId: message.authorId,
                                  text:
                                      "Unsupported message type: ${message.metadata?["eventType"]}",
                                ),
                                receivedBackgroundColor: Colors.red,
                                sentBackgroundColor: Colors.red,
                                index: index,
                              )
                            : SizedBox.shrink(),
                        textMessageBuilder:
                            (
                              context,
                              message,
                              index, {
                              required bool isSentByMe,
                              MessageGroupStatus? groupStatus,
                            }) => Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                SizedBox(height: 8),

                                FlyerChatTextMessage(
                                  topWidget: Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => showAboutDialog(
                                        context: context,
                                      ), // TODO: Show user profile
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 8,
                                        children: [
                                          Avatar(
                                            userId: message.authorId,
                                            headers: headers,
                                          ),
                                          Text(
                                            message.metadata?["displayName"] ??
                                                message.authorId,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  message: message.copyWith(
                                    text: message.text.replaceAllMapped(
                                      urlRegex,
                                      (match) =>
                                          "[${match.group(0)}](${match.group(0)})",
                                    ),
                                  ),
                                  showTime: true,
                                  index: index,
                                  onLinkTap: (url, _) => ref
                                      .watch(LaunchHelper.provider)
                                      .launchUrl(Uri.parse(url)),
                                  linksDecoration: TextDecoration.underline,
                                  sentLinksColor: Colors.blue,
                                  receivedLinksColor: Colors.blue,
                                ),
                              ],
                            ),
                        linkPreviewBuilder: (_, message, isSentByMe) =>
                            LinkPreview(
                              text:
                                  urlRegex.firstMatch(message.text)?.group(0) ??
                                  "",
                              backgroundColor: isSentByMe
                                  ? theme.colorScheme.inversePrimary
                                  : theme.colorScheme.surfaceContainerLow,
                              insidePadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              linkPreviewData: message.linkPreviewData,
                              onLinkPreviewDataFetched: (linkPreviewData) => ref
                                  .watch(controllerProvider.notifier)
                                  .updateMessage(
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
                              message: message,
                              index: index,
                              headers: headers,
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
                      ),
                      onMessageSend: ref
                          .watch(controllerProvider.notifier)
                          .send,
                      resolveUser: ref
                          .watch(controllerProvider.notifier)
                          .resolveUser,
                      chatController: controller,
                    ),
                  ),
            );
          },
        );
  }
}
