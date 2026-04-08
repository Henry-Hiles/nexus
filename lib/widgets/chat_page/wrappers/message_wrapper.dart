import "package:cross_cache/cross_cache.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/chat_page/lazy_loading/message_displayname.dart";
import "package:timeago/timeago.dart";

class MessageWrapper extends ConsumerWidget {
  final Message message;
  final Widget child;
  final MessageGroupStatus? groupStatus;
  const MessageWrapper(this.message, this.child, this.groupStatus, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final error = message.metadata?["error"];
    final clientState = ref.watch(ClientStateController.provider);

    return ClipRRect(
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
                    Row(
                      spacing: 4,
                      children: [
                        Flexible(
                          child: MessageDisplayname(
                            message,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (message.deliveredAt != null &&
                            groupStatus?.isFirst != false)
                          Tooltip(
                            message: message.deliveredAt!.toString(),
                            child: Text(
                              format(message.deliveredAt!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  child,
                  if (error != null && error != "not sent")
                    Text(
                      error,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        clientState?.homeserverUrl == null ||
                            message.reactions == null
                        ? []
                        : message.reactions!.mapTo((reaction, reactors) {
                            final selected = reactors.contains(
                              clientState!.userId,
                            );
                            return SizedBox(
                              child: ChoiceChip(
                                showCheckmark: false,
                                selected: selected,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    reaction.startsWith("mxc://")
                                        ? Image(
                                            height: 20,
                                            image: CachedNetworkImage(
                                              headers: ref.headers,
                                              Uri.parse(reaction)
                                                  .mxcToHttps(
                                                    clientState.homeserverUrl!,
                                                  )
                                                  .toString(),
                                              ref.watch(
                                                CrossCacheController.provider,
                                              ),
                                            ),
                                          )
                                        : Text(reaction),
                                    Text(reactors.length.toString()),
                                  ],
                                ),
                                onSelected: (value) {}, // TODO
                              ),
                            );
                          }).toList(),
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
