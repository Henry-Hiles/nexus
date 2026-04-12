import "package:cross_cache/cross_cache.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/main.dart";

class ReactionRow extends ConsumerWidget {
  final Message message;
  const ReactionRow(this.message, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(ClientStateController.provider);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: clientState?.homeserverUrl == null || message.reactions == null
          ? []
          : message.reactions!
                .mapTo(
                  (reaction, reactors) => HookBuilder(
                    builder: (context) {
                      final enabled = useState(true);
                      final selected = reactors.contains(clientState!.userId);
                      return SizedBox(
                        child: Tooltip(
                          message: reactors.join(", "),
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
                            onSelected: enabled.value
                                ? (value) async {
                                    enabled.value = false;
                                    try {
                                      final roomId = ref.watch(
                                        SelectedRoomController.provider.select(
                                          (value) => value?.metadata?.id,
                                        ),
                                      );
                                      if (roomId == null ||
                                          clientState.userId == null) {
                                        return;
                                      }

                                      final controller = ref.watch(
                                        RoomChatController.provider(
                                          roomId,
                                        ).notifier,
                                      );

                                      if (selected) {
                                        await controller
                                            .removeReaction(
                                              reaction,
                                              message,
                                              clientState.userId!,
                                            )
                                            .onError(showError);
                                      } else {
                                        await controller
                                            .sendReaction(reaction, message)
                                            .onError(showError);
                                      }
                                    } finally {
                                      enabled.value = true;
                                    }
                                  }
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
    );
  }
}
