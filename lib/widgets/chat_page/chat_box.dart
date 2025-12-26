import "dart:io";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/avatar_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/reply_preview.dart";
import "package:nexus/widgets/loading.dart";

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
    final triggerCharacter = useState("");
    final query = useState("");

    Future<void> send() => ref
        .watch(RoomChatController.provider(room).notifier)
        .send(controller.value.text, replyTo: replyToMessage);

    final node = useFocusNode(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || Platform.isAndroid || Platform.isIOS) {
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            send();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            onDismiss();
            return KeyEventResult.handled;
          }
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
          child: Column(
            children: [
              ReplyPreview(
                replyToMessage: replyToMessage,
                onDismiss: onDismiss,
                room: room,
              ),
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: room.canSendDefaultMessages
                    ? Row(
                        spacing: 8,
                        children: [
                          PopupMenuButton(
                            itemBuilder: (context) => [],
                            icon: Icon(Icons.add),
                          ),
                          Expanded(
                            child: FlutterTagger(
                              triggerStrategy: TriggerStrategy.eager,
                              overlay: Padding(
                                padding: EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  child: Container(
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
                                    padding: EdgeInsets.all(8),
                                    child: switch (triggerCharacter.value) {
                                      "@" =>
                                        ref
                                            .watch(
                                              MembersController.provider(room),
                                            )
                                            .betterWhen(
                                              data: (members) => ListView(
                                                children:
                                                    (query.value.isEmpty
                                                            ? members
                                                            : members.where(
                                                                (member) =>
                                                                    member
                                                                        .senderId
                                                                        .contains(
                                                                          query
                                                                              .value,
                                                                        ) ||
                                                                    (member.content["displayname"]
                                                                                as String?)
                                                                            ?.contains(
                                                                              query.value,
                                                                            ) ==
                                                                        true,
                                                              ))
                                                        .map(
                                                          (member) => ListTile(
                                                            leading: AvatarOrHash(
                                                              ref
                                                                  .watch(
                                                                    AvatarController.provider(
                                                                      member
                                                                          .content["avatar_url"]
                                                                          .toString(),
                                                                    ),
                                                                  )
                                                                  .whenOrNull(
                                                                    data:
                                                                        (
                                                                          data,
                                                                        ) =>
                                                                            data,
                                                                  ),
                                                              member
                                                                  .content["displayname"]
                                                                  .toString(),
                                                              headers: room
                                                                  .client
                                                                  .headers,
                                                            ),
                                                            title: Text(
                                                              member.content["displayname"]
                                                                      as String? ??
                                                                  member
                                                                      .senderId,
                                                            ),
                                                            onTap: () => controller
                                                                .value
                                                                .addTag(
                                                                  id: "member",
                                                                  name: member
                                                                      .senderId
                                                                      .substring(
                                                                        1,
                                                                      )
                                                                      .split(
                                                                        ":",
                                                                      )
                                                                      .first,
                                                                ),
                                                          ),
                                                        )
                                                        .toList(),
                                              ),
                                            ),
                                      "#" => Text("Todo"),
                                      _ => Loading(),
                                    },
                                  ),
                                ),
                              ),
                              controller: controller.value,
                              onSearch: (newQuery, newTriggerCharacter) {
                                triggerCharacter.value = newTriggerCharacter;
                                query.value = newQuery;
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
                    : Text(
                        "You don't have permission to send messages here...",
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
