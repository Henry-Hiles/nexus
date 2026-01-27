import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/relation_type.dart";

class RelationPreview extends ConsumerWidget {
  final Message? relatedMessage;
  final RelationType relationType;
  final VoidCallback onDismiss;
  const RelationPreview({
    required this.relatedMessage,
    required this.relationType,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (relatedMessage == null) return SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 8,
        children: [
          SizedBox(width: 4),
          if (relationType == RelationType.edit)
            Text(
              "Editing message:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          // AvatarOrHash(
          //   ref
          //       .watch(
          //         AvatarController.provider(
          //           relatedMessage!.metadata!["avatarUrl"],
          //         ),
          //       )
          //       .whenOrNull(data: (data) => data),
          //   relatedMessage!.metadata!["displayName"].toString(),
          //   headers: room.client.headers,
          //   height: 16,
          // ),
          Text(
            relatedMessage!.metadata?["displayName"] ??
                relatedMessage!.authorId,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              (relatedMessage is TextMessage)
                  ? (relatedMessage as TextMessage).text
                  : relatedMessage?.metadata?["body"] ??
                        relatedMessage?.metadata?["eventType"],
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
            ),
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
