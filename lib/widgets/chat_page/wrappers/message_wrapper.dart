import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_displayname.dart";

class MessageWrapper extends StatelessWidget {
  final Message message;
  final Widget child;
  final MessageGroupStatus? groupStatus;
  const MessageWrapper(this.message, this.child, this.groupStatus, {super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    child: AnimatedContainer(
      padding: message.metadata?["flashing"] == true
          ? EdgeInsets.all(8)
          : EdgeInsets.all(0),
      color: message.metadata?["flashing"] == true
          ? Theme.of(context).colorScheme.onSurface.withAlpha(50)
          : Colors.transparent,
      duration: Duration(milliseconds: 250),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          groupStatus?.isFirst != false
              ? MessageAvatar(message, height: 40)
              : SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                if (groupStatus?.isFirst != false)
                  MessageDisplayname(
                    message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                child,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
