import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/avatar_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class ReplyPreview extends ConsumerWidget {
  final Message? replyToMessage;
  final VoidCallback onDismiss;
  final Room room;
  const ReplyPreview({
    required this.replyToMessage,
    required this.onDismiss,
    required this.room,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (replyToMessage == null) return SizedBox.shrink();
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(width: 4),
          AvatarOrHash(
            ref
                .watch(
                  AvatarController.provider(
                    replyToMessage!.metadata!["avatarUrl"],
                  ),
                )
                .whenOrNull(data: (data) => data),
            replyToMessage!.metadata!["displayName"].toString(),
            headers: room.client.headers,
            height: 16,
          ),
          Text(
            replyToMessage!.metadata?["displayName"] ??
                replyToMessage!.authorId,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: (replyToMessage is TextMessage)
                ? Text(
                    (replyToMessage as TextMessage).text,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
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
    );
  }
}
