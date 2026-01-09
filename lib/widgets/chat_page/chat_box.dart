import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/chat_page/mention_overlay.dart";
import "package:nexus/widgets/chat_page/relation_preview.dart";

class ChatBox extends HookConsumerWidget {
  final Message? relatedMessage;
  final RelationType relationType;
  final VoidCallback onDismiss;
  final Room room;
  const ChatBox({
    required this.relatedMessage,
    required this.relationType,
    required this.onDismiss,
    required this.room,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useRef(FlutterTaggerController());
    final triggerCharacter = useState("");
    final query = useState("");

    if (relationType == RelationType.edit &&
        relatedMessage is TextMessage &&
        controller.value.text.isEmpty) {
      final text = (relatedMessage as TextMessage).text;
      final splitText = relatedMessage?.replyToMessageId == null
          ? text
          : text.split("\n\n").sublist(1).join("\n\n");
      final notEmpty = splitText.isEmpty ? text : splitText;
      controller.value.text = notEmpty.startsWith("* ")
          ? notEmpty.substring(2)
          : notEmpty;
    }

    void send() {
      if (controller.value.text.isEmpty) return;
      ref
          .watch(RoomChatController.provider(room).notifier)
          .send(
            controller.value.formattedText,
            relation: relatedMessage,
            relationType: relationType,
            tags: controller.value.tags,
          );
      onDismiss();
      controller.value.text = "";
    }

    final node = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && !Platform.isAndroid && !Platform.isIOS) {
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            send();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            onDismiss();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
    )..requestFocus();

    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
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
                relatedMessage: relatedMessage,
                relationType: relationType,
                onDismiss: onDismiss,
                room: room,
              ),
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    PopupMenuButton(
                      itemBuilder: (context) => [],
                      icon: Icon(Icons.add),
                      enabled: room.canSendDefaultMessages,
                    ),
                    Expanded(
                      child: FlutterTagger(
                        triggerStrategy: TriggerStrategy.eager,
                        overlay: MentionOverlay(
                          room,
                          query: query.value,
                          triggerCharacter: triggerCharacter.value,
                          addTag: ({required id, required name}) {
                            controller.value.addTag(id: id, name: name);
                            node.requestFocus();
                          },
                        ),
                        controller: controller.value,
                        onSearch: (newQuery, newTriggerCharacter) {
                          triggerCharacter.value = newTriggerCharacter;
                          query.value = newQuery;
                        },
                        triggerCharacterAndStyles: {"@": style, "#": style},
                        builder: (context, key) => TextFormField(
                          enabled: room.canSendDefaultMessages,
                          maxLines: 12,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: room.canSendDefaultMessages
                                ? "Your message here..."
                                : "You don't have permission to send messages in this room...",
                            border: InputBorder.none,
                          ),
                          controller: controller.value,
                          key: key,
                          autofocus: true,
                          focusNode: node,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: room.canSendDefaultMessages ? send : null,
                      icon: Icon(Icons.send),
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
