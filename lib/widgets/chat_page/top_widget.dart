import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/chat_page/html/quoted.dart";

class TopWidget extends ConsumerWidget {
  final Message message;
  final bool alwaysShow;
  final Map<String, String> headers;
  final MessageGroupStatus? groupStatus;
  const TopWidget(
    this.message, {
    required this.headers,
    required this.groupStatus,
    this.alwaysShow = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Builder(
        builder: (_) {
          final replyMessage = message.metadata?["reply"] as TextMessage?;

          if (replyMessage == null) return SizedBox.shrink();
          final smallerText = message is TextMessage
              ? replyMessage.text.substring(
                  0,
                  min(
                    max(
                      max(
                        (message as TextMessage).text.length - 20,
                        message.metadata?["displayName"].length,
                      ),
                      5,
                    ),
                    replyMessage.text.length,
                  ),
                )
              : null;
          final replyText =
              (smallerText == null ||
                  smallerText.length == replyMessage.text.length)
              ? replyMessage.text
              : "$smallerText...";

          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: Text("TODO: Scroll to original message"),
                ), // TODO
              ),
              child: Quoted(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Avatar(
                      userId: replyMessage.authorId,
                      headers: headers,
                      size: 16,
                    ),
                    Flexible(
                      child: Text(
                        replyMessage.metadata?["displayName"] ??
                            replyMessage.authorId,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        replyText,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      if (alwaysShow ||
          groupStatus?.isFirst != false ||
          message.metadata?["reply"] != null)
        InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (_) =>
                Dialog(child: Text("TODO: Show user profile")), // TODO
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Avatar(userId: message.authorId, headers: headers),
              Flexible(
                child: Text(
                  message.metadata?["displayName"] ?? message.authorId,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      SizedBox(height: 4),
    ],
  );
}
