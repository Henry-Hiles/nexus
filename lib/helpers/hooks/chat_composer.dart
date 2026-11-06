import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/composer_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/relation_type.dart";

final class ChatComposer({
  required final int? relatedEvent,
  required final RelationType relationType,
  required final ComposerDraftController notifier,
  required final FocusNode node,
}) {
  factory use(WidgetRef ref, ComposerParams composer) {
    final provider = ComposerDraftController.provider(composer);
    final node = useFocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == .escape) {
          ref.read(provider.notifier).dismiss();
          // Ending an edit replaces the text field, losing its focus
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => node.requestFocus(),
          );
          return .handled;
        }

        return .ignored;
      },
    );
    final (relatedEvent, relationType) = ref.watch(
      provider.select((draft) => (draft.relatedEvent, draft.relationType)),
    );

    return .new(
      relatedEvent: relatedEvent,
      relationType: relationType,
      notifier: ref.watch(provider.notifier),
      node: node,
    );
  }

  int? get repliedEventRowId => relationType == .reply ? relatedEvent : null;

  void relate(int rowId, RelationType type) {
    notifier.relate(rowId, type);
    // Starting an edit replaces the text field, losing its focus
    WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus());
  }
}
