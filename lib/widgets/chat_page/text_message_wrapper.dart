import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_link_previewer/flutter_link_previewer.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/chat_page/html/html.dart";
import "package:nexus/widgets/chat_page/message_wrapper.dart";
import "package:nexus/widgets/chat_page/reply_widget.dart";

class TextMessageWrapper extends StatelessWidget {
  final Message message;
  final String? content;
  final Room room;
  final MessageGroupStatus? groupStatus;
  final Future<void> Function(Message oldMessage, Message newMessage)
  updateMessage;
  final bool isSentByMe;
  final Widget? extra;
  final OnTapReply onTapReply;

  const TextMessageWrapper(
    this.message, {
    this.content,
    this.onTapReply,
    required this.room,
    required this.updateMessage,
    required this.groupStatus,
    required this.isSentByMe,
    this.extra,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textMessage = message is TextMessage ? message as TextMessage : null;

    return MessageWrapper(
      message,
      ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSentByMe
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReplyWidget(
                message,
                room: room,
                groupStatus: groupStatus,
                onTapReply: onTapReply,
              ),
              if (content != null)
                Html(
                  textStyle: message.metadata?["big"] == true
                      ? TextStyle(fontSize: 32)
                      : null,
                  content!
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
                      .replaceAll("\n", "<br class=\"fake-break\"/>"),
                ),
              if (textMessage?.editedAt != null)
                Text("(edited)", style: theme.textTheme.labelSmall),
              if (textMessage != null)
                LinkPreview(
                  text: textMessage.text,
                  backgroundColor: isSentByMe
                      ? colorScheme.inversePrimary
                      : colorScheme.surfaceContainerLow,
                  outsidePadding: EdgeInsets.only(top: 4),
                  insidePadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  linkPreviewData: message.metadata?["linkPreviewData"],
                  onLinkPreviewDataFetched: (linkPreviewData) => updateMessage(
                    message,
                    message.copyWith(
                      metadata: {
                        ...(message.metadata ?? {}),
                        "linkPreviewData": linkPreviewData,
                      },
                    ),
                  ),
                ),
              if (extra != null) extra!,
            ],
          ),
        ),
      ),
      groupStatus,
      room,
    );
  }
}
