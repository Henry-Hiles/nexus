import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_displayname.dart";

class RelationPreview extends ConsumerWidget {
  final Message? relatedMessage;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final bool shouldMention;
  final VoidCallback toggleShouldMention;
  final Room room;

  const RelationPreview(
    this.relatedMessage, {
    required this.room,
    required this.relationType,
    required this.onDismiss,
    required this.shouldMention,
    required this.toggleShouldMention,
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
          MessageAvatar(relatedMessage!, room),
          MessageDisplayname(
            relatedMessage!,
            room,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              relatedMessage?.metadata?["body"] ??
                  relatedMessage?.metadata?["eventType"],
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
            ),
          ),

          if (relationType == RelationType.reply)
            TextButton(
              onPressed: toggleShouldMention,
              child: Text(
                shouldMention ? "@On" : "@Off",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: shouldMention ? null : Theme.of(context).disabledColor,
                ),
              ),
            ),
          IconButton(
            tooltip:
                "Cancel ${relationType == RelationType.edit ? "edit" : "reply"}",
            onPressed: onDismiss,
            icon: Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
