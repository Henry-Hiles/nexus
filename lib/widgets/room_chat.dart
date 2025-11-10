import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_link_previewer/flutter_link_previewer.dart";
import "package:flyer_chat_image_message/flyer_chat_image_message.dart";
import "package:flyer_chat_system_message/flyer_chat_system_message.dart";
import "package:flyer_chat_text_message/flyer_chat_text_message.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/room_chat_controller.dart";

class RoomChat extends HookConsumerWidget {
  const RoomChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = RoomChatController.provider("1");
    final theme = Theme.of(context);
    return Chat(
      currentUserId: "foo",
      theme: ChatTheme.fromThemeData(theme).copyWith(
        colors: ChatColors.fromThemeData(theme).copyWith(
          primary: theme.colorScheme.primaryContainer,
          onPrimary: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      builders: Builders(
        composerBuilder: (_) => Composer(),
        textMessageBuilder:
            (
              context,
              message,
              index, {
              required bool isSentByMe,
              MessageGroupStatus? groupStatus,
            }) => FlyerChatTextMessage(
              message: message.copyWith(
                text: message.text.replaceAllMapped(
                  RegExp(
                    r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+",
                  ),
                  (match) => "[${match.group(0)}](${match.group(0)})",
                ),
              ),
              index: index,
              linksDecoration: TextDecoration.underline,
            ),
        linkPreviewBuilder: (_, message, isSentByMe) {
          return LinkPreview(
            text: message.text,
            backgroundColor: isSentByMe
                ? theme.colorScheme.inversePrimary
                : theme.colorScheme.surfaceContainerLow,
            insidePadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            linkPreviewData: message.linkPreviewData,
            onLinkPreviewDataFetched: (linkPreviewData) {
              ref
                  .watch(controller)
                  .updateMessage(
                    message,
                    message.copyWith(linkPreviewData: linkPreviewData),
                  );
            },
            // You can still customize the appearance
            parentContent: message.text,
          );
        },
        imageMessageBuilder:
            (
              _,
              message,
              index, {
              required bool isSentByMe,
              MessageGroupStatus? groupStatus,
            }) => FlyerChatImageMessage(message: message, index: index),
        systemMessageBuilder:
            (
              _,
              message,
              index, {
              required bool isSentByMe,
              MessageGroupStatus? groupStatus,
            }) => FlyerChatSystemMessage(message: message, index: index),
      ),
      onMessageSend: ref.watch(controller.notifier).send,
      resolveUser: (id) async => User(id: id, imageSource: "foo"),
      chatController: ref.watch(controller),
    );
  }
}
