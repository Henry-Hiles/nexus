import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/event_preview.dart";

class RelationPreview extends ConsumerWidget {
  final Event? relatedEvent;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final bool shouldMention;
  final VoidCallback toggleShouldMention;

  const RelationPreview(
    this.relatedEvent, {
    required this.relationType,
    required this.onDismiss,
    required this.shouldMention,
    required this.toggleShouldMention,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (relatedEvent == null) return SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 8,
        children: [
          if (relationType == RelationType.edit)
            Text(
              "Editing message:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: EventPreview(relatedEvent!),
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
