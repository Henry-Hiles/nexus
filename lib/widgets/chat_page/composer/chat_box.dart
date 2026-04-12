import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/power_level_controller.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/chat_page/composer/mention_overlay.dart";
import "package:nexus/widgets/chat_page/composer/relation_preview.dart";
import "package:nexus/widgets/chat_page/emoji_picker_button.dart";

class ChatBox extends HookConsumerWidget {
  final Message? relatedMessage;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final FocusNode? node;
  final Future<void> Function(
    String text, {
    required bool shouldMention,
    required IList<Tag> tags,
  })
  onSend;
  const ChatBox({
    required this.relatedMessage,
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

    if (relationType == RelationType.edit &&
        relatedMessage is TextMessage &&
        controller.value.text.isEmpty) {
      controller.value.text = relatedMessage?.metadata?["editSource"] ?? "";
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

    final canSendMessages = ref.watch(
      PowerLevelController.provider(
        PowerLevelConfig(eventType: "m.room.message"),
      ),
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsetsGeometry.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          child: Column(
            children: [
              RelationPreview(
                relatedMessage,
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
                  children: [
                    EmojiPickerButton(
                      context: context,
                      onSelection: (_) => node?.requestFocus(),
                      controller: controller.value,
                    ),
                    PopupMenuButton(
                      tooltip: "Add media",
                      enabled: canSendMessages,
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
                          enabled: canSendMessages,
                          maxLines: 12,
                          minLines: 1,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: canSendMessages
                                ? "Your message here..."
                                : "You don't have permission to send messages in this room...",
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
                      onPressed: !canSendMessages ? null : send,
                      icon: Icon(Icons.send),
                      tooltip: "Send message",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
