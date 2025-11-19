import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";

class ChatBox extends StatelessWidget {
  final Message? replyToMessage;
  final VoidCallback onDismiss;
  final Map<String, String> headers;
  const ChatBox({
    required this.replyToMessage,
    required this.onDismiss,
    required this.headers,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Composer(
    sigmaX: 0,
    sigmaY: 0,
    sendIconColor: Theme.of(context).colorScheme.primary,
    sendOnEnter: true,
    topWidget: replyToMessage == null
        ? null
        : ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                spacing: 8,
                children: [
                  Avatar(
                    userId: replyToMessage!.authorId,
                    headers: headers,
                    size: 16,
                  ),
                  Text(
                    replyToMessage!.metadata?["displayName"] ??
                        replyToMessage!.authorId,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: (replyToMessage is TextMessage)
                        ? Text(
                            (replyToMessage as TextMessage).text,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                          )
                        : SizedBox(),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ),
    autofocus: true,
  );
}
