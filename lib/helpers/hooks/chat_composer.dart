import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/relation_type.dart";

final class ChatComposer({
  required final ValueNotifier<int?> relatedEvent,
  required final ValueNotifier<RelationType> relationType,
  required final FocusNode node,
}) {
  factory use() {
    final relatedEvent = useState<int?>(null);
    final relationType = useState(RelationType.reply);
    final node = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == .escape) {
          relatedEvent.value = null;
          return .handled;
        }

        return .ignored;
      },
    );

    return .new(
      relatedEvent: relatedEvent,
      relationType: relationType,
      node: node,
    );
  }

  int? get repliedEventRowId =>
      relationType.value == .reply ? relatedEvent.value : null;

  void relate(int rowId, RelationType type) {
    relatedEvent.value = rowId;
    relationType.value = type;
    node.requestFocus();
  }
}
