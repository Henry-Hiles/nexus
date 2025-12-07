import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/room_chat_controller.dart";

class ChatBox extends HookConsumerWidget {
  final Message? replyToMessage;
  final VoidCallback onDismiss;
  final Room room;
  const ChatBox({
    required this.replyToMessage,
    required this.onDismiss,
    required this.room,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useRef(FlutterTaggerController());

    Future<void> send() => ref
        .watch(RoomChatController.provider(room).notifier)
        .send(controller.value.text);

    final node = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !(Platform.isAndroid || Platform.isIOS) ^
                HardwareKeyboard.instance.isShiftPressed) {
          send();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );

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
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: // TODO: This doesn't work?
            room.canSendDefaultMessages
                ? Row(
                    spacing: 8,
                    children: [
                      PopupMenuButton(
                        itemBuilder: (context) => [],
                        icon: Icon(Icons.add),
                      ),
                      Expanded(
                        child: FlutterTagger(
                          overlay: SizedBox(),
                          controller: controller.value,
                          onSearch: (query, triggerCharacter) {
                            triggerCharacter == "#";
                            if (controller.value.tags.isEmpty) {
                              controller.value.addTag(
                                id: "id",
                                name: "name",
                              ); // TODO: RM
                            }
                          },
                          triggerCharacterAndStyles: {
                            "@": style,
                            "#": style,
                            ":": style,
                          },
                          builder: (context, key) => TextFormField(
                            maxLines: 12,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: "Your message here...",
                              border: InputBorder.none,
                            ),
                            controller: controller.value,
                            key: key,
                            autofocus: true,
                            focusNode: node,
                          ),
                        ),
                      ),
                      IconButton(onPressed: send, icon: Icon(Icons.send)),
                    ],
                  )
                : Text("You don't have permission to send messages here..."),
            // Composer(
            //     textEditingController: controller.value,
            //     key: key,
            //     sigmaY: 0,
            //     sendIconColor: theme.colorScheme.primary,
            //     sendOnEnter: true,
            //     topWidget: replyToMessage == null
            //         ? null
            //         : ColoredBox(
            //             color: theme.colorScheme.surfaceContainer,
            //             child: Padding(
            //               padding: EdgeInsets.symmetric(
            //                 horizontal: 16,
            //                 vertical: 4,
            //               ),
            //               child: Row(
            //                 spacing: 8,
            //                 children: [
            //                   Avatar(
            //                     userId: replyToMessage!.authorId,
            //                     headers: room.client.headers,
            //                     size: 16,
            //                   ),
            //                   Text(
            //                     replyToMessage!.metadata?["displayName"] ??
            //                         replyToMessage!.authorId,
            //                     style: theme.textTheme.labelMedium?.copyWith(
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                   Expanded(
            //                     child: (replyToMessage is TextMessage)
            //                         ? Text(
            //                             (replyToMessage as TextMessage).text,
            //                             overflow: TextOverflow.ellipsis,
            //                             style: theme.textTheme.labelMedium,
            //                             maxLines: 1,
            //                           )
            //                         : SizedBox(),
            //                   ),
            //                   IconButton(
            //                     onPressed: onDismiss,
            //                     icon: Icon(Icons.close),
            //                     iconSize: 20,
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //     autofocus: true,
            //   ),
          ),
        ),
      ),
    );
  }
}
