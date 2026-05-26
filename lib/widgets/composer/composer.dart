import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/power_level_controller.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/mention_overlay.dart";
import "package:nexus/widgets/composer/relation_preview.dart";
import "package:nexus/widgets/emoji_picker_button.dart";

class Composer extends HookConsumerWidget {
  final String roomId;
  final Event? relatedEvent;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final FocusNode? node;
  final Future<void> Function(
    String text, {
    required bool shouldMention,
    required IList<Tag> tags,
  })
  onSend;
  const Composer(
    this.roomId, {
    required this.relatedEvent,
    required this.relationType,
    required this.onDismiss,
    required this.onSend,
    this.node,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useRef(FlutterTaggerController());
    final triggerCharacter = useState("");
    final shouldMention = useState(true);
    final query = useState("");

    if (relationType == RelationType.edit && controller.value.text.isEmpty) {
      controller.value.text = relatedEvent?.localContent?.editSource ?? "";
    }

    void send() {
      if (controller.value.text.isEmpty) return;
      onSend(
        controller.value.formattedText,
        shouldMention: shouldMention.value,
        tags: controller.value.tags.toIList(),
      );

      onDismiss();
      controller.value.text = "";
    }

    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: EdgeInsetsGeometry.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: Column(
          children: [
            RelationPreview(
              relatedEvent,
              shouldMention: shouldMention.value,
              toggleShouldMention: () =>
                  shouldMention.value = !shouldMention.value,
              relationType: relationType,
              onDismiss: onDismiss,
            ),
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    ref.watch(
                      PowerLevelController.provider(
                        PowerLevelConfig(
                          eventType: EventType.message,
                          roomId: roomId,
                        ),
                      ),
                    )
                    ? [
                        EmojiPickerButton(
                          context: context,
                          onSelection: (_) => node?.requestFocus(),
                          controller: controller.value,
                        ),
                        PopupMenuButton(
                          tooltip: "Add media",
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: ListTile(
                                title: Text("Camera"),
                                leading: Icon(Icons.add_a_photo),
                              ),
                            ),
                            PopupMenuItem(
                              child: ListTile(
                                title: Text("Gallery"),
                                leading: Icon(Icons.add_photo_alternate),
                              ),
                            ),
                            PopupMenuItem(
                              child: ListTile(
                                title: Text("Files"),
                                leading: Icon(Icons.attachment),
                              ),
                            ),
                          ],
                          icon: Icon(Icons.add),
                        ),
                        Expanded(
                          child: FlutterTagger(
                            triggerStrategy: TriggerStrategy.eager,
                            overlay: MentionOverlay(
                              roomId,
                              query: query.value,
                              triggerCharacter: triggerCharacter.value,
                              addTag: ({required id, required name}) {
                                controller.value.addTag(id: id, name: name);
                                node?.requestFocus();
                              },
                            ),
                            controller: controller.value,
                            onSearch: (newQuery, newTriggerCharacter) {
                              triggerCharacter.value = newTriggerCharacter;
                              query.value = newQuery;
                            },
                            triggerCharacterAndStyles: {"@": style, "#": style},
                            builder: (context, key) => TextFormField(
                              maxLines: 12,
                              minLines: 1,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Your message here...",
                                border: InputBorder.none,
                              ),
                              controller: controller.value,
                              key: key,
                              onFieldSubmitted: (_) => send(),
                              // Don't defocus on submit
                              onEditingComplete: () {},
                              textInputAction: TextInputAction.done,
                              focusNode: node,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: send,
                          icon: Icon(Icons.send),
                          tooltip: "Send message",
                        ),
                      ]
                    : [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(8),
                            child: Text(
                              "You don't have permission to send messages in this room...",
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
