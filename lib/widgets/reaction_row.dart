import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/reactions_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/main.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

class ReactionRow extends ConsumerWidget {
  final Event event;
  const ReactionRow(this.event, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(ClientStateController.provider);

    return switch (ref.watch(
      ReactionsController.provider(
        .new(roomId: event.roomId, eventRowId: event.rowId),
      ),
    )) {
      AsyncData(value: final IMap<String, IList<String>>? reactors) ||
      AsyncLoading(value: final reactors) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: event.reactions
            .where((_, value) => value != 0)
            .mapTo(
              (reaction, count) => HookBuilder(
                builder: (context) {
                  final enabled = useState(true);

                  final selected =
                      reactors?[reaction]?.contains(clientState!.userId) ??
                      false;
                  return Tooltip(
                    message: reactors?[reaction]?.join(", ") ?? "",
                    child: ChoiceChip(
                      showCheckmark: false,
                      selected: selected,
                      label: Row(
                        mainAxisSize: .min,
                        spacing: 8,
                        children: [
                          Flexible(
                            child: reaction.startsWith("mxc://")
                                ? Image(
                                    height: 20,
                                    image: CachedNetworkImage(
                                      headers: ref.headers,
                                      Uri.parse(reaction)
                                          .mxcToHttps(
                                            clientState!.homeserverUrl!,
                                          )
                                          .toString(),
                                      ref.watch(CrossCacheController.provider),
                                    ),
                                  )
                                : Text(reaction, overflow: .ellipsis),
                          ),
                          Text(count.toString(), overflow: .ellipsis),
                        ],
                      ),
                      onSelected: enabled.value
                          ? (value) async {
                              enabled.value = false;
                              try {
                                final controller = ref.watch(
                                  RoomChatController.provider(
                                    event.roomId,
                                  ).notifier,
                                );

                                if (selected) {
                                  await controller
                                      .removeReaction(
                                        reaction,
                                        event,
                                        clientState!.userId!,
                                      )
                                      .onError(showError);
                                } else {
                                  await controller
                                      .sendReaction(reaction, event)
                                      .onError(showError);
                                }
                              } finally {
                                enabled.value = true;
                              }
                            }
                          : null,
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),

      AsyncError(:final error, :final stackTrace) => ErrorDialog(
        error,
        stackTrace,
      ),
    };
  }
}
