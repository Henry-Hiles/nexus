import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_displayname.dart";

class RelationPreview extends ConsumerWidget {
  final Message? relatedMessage;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final bool shouldMention;
  final VoidCallback toggleShouldMention;

  const RelationPreview(
    this.relatedMessage, {
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
          if (relationType == RelationType.edit)
            Text(
              "Editing message:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

          MessageAvatar(relatedMessage!),

          Expanded(
            child: Row(
              spacing: 8,
              children: [
                Flexible(
                  child: MessageDisplayname(
                    relatedMessage!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    relatedMessage?.metadata?["body"] ??
                        relatedMessage?.metadata?["eventType"] ??
                        "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
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
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
