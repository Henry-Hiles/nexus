import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/helpers/extension_helper.dart";

class TopWidget extends ConsumerWidget {
  final Message message;
  final Map<String, String> headers;
  const TopWidget(this.message, {required this.headers, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (message.replyToMessageId != null) ...[
        ref
            .watch(MessageController.provider(message.replyToMessageId!))
            .betterWhen(
              loading: SizedBox.shrink,
              data: (replyMessage) {
                if (replyMessage == null) return SizedBox.shrink();
                final replyText = message is TextMessage
                    ? replyMessage.text.substring(
                        0,
                        min(
                          max(
                            min(
                              (message as TextMessage).text.length - 20,
                              replyMessage.text.length,
                            ),
                            40,
                          ),
                          replyMessage.text.length,
                        ),
                      )
                    : replyMessage.text;
                return InkWell(
                  onTap: () => showAboutDialog(
                    context: context,
                  ), // TODO: Scroll to message
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 4,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Avatar(
                            userId: replyMessage.authorId,
                            headers: headers,
                            size: 16,
                          ),
                          Text(
                            replyMessage.metadata?["displayName"] ??
                                replyMessage.authorId,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
        SizedBox(height: 12),
      ],
      InkWell(
        onTap: () =>
            showAboutDialog(context: context), // TODO: Show user profile
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Avatar(userId: message.authorId, headers: headers),
            Text(
              message.metadata?["displayName"] ?? message.authorId,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      SizedBox(height: 4),
    ],
  );
}
