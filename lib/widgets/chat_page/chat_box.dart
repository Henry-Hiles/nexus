import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_ui/flutter_chat_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:matrix/matrix.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/form_text_input.dart";

class ChatBox extends HookWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = useRef(FlutterTaggerController());
    final trigger = useState<String?>(null);
    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FlutterTagger(
          overlay: SizedBox(),
          controller: controller.value,
          onSearch: (query, triggerCharacter) {
            triggerCharacter == "#";
            if (controller.value.tags.isEmpty)
              controller.value.addTag(id: "id", name: "name");
          },
          triggerCharacterAndStyles: {"@": style, "#": style},
          builder: (context, key) => TextFormField(controller: controller.value, key: key,autofocus: true,onFieldSubmitted: (_) {
            
          },) 
		//   Composer(
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
      ],
    );
  }
}
