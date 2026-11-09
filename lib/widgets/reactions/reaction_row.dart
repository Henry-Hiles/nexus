import "package:flutter/gestures.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/reactions.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/reaction_group.dart";
import "package:nexus/widgets/common/error_dialog.dart";
import "package:nexus/widgets/reactions/reaction_key.dart";
import "package:nexus/widgets/reactions/reactions_popover.dart";
import "package:nexus/main.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

class const ReactionRow(final Event event, {super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(ClientStateController.provider);

    return Padding(
      padding: .only(top: 4),
      child: switch (ref.watch(
        ReactionsController.provider(
          .new(roomId: event.roomId, eventRowId: event.rowId),
        ),
      )) {
        AsyncData(value: final IMap<String, ReactionGroup>? reactors) ||
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
                        reactors?[reaction]?.senders.contains(
                          clientState!.userId,
                        ) ??
                        false;
                    void showReactions(PositionedGestureDetails details) =>
                        context.showAdaptivePopover(
                          (_) => ReactionsPopover(
                            event,
                            initialReaction: reaction,
                          ),
                          anchor: context.globalRectAt(details.globalPosition),
                        );

                    return GestureDetector(
                      onSecondaryTapUp: showReactions,
                      onLongPressStart: showReactions,
                      child: Tooltip(
                        // Long press opens the reactions popover instead
                        triggerMode: .manual,
                        message: reactors?[reaction]?.shortcode ?? reaction,
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: selected,
                          label: Row(
                            mainAxisSize: .min,
                            spacing: 8,
                            children: [
                              Flexible(
                                child: ReactionKey(reaction, height: 20),
                              ),
                              Text(count.toString(), overflow: .ellipsis),
                            ],
                          ),
                          onSelected: enabled.value
                              ? (value) async {
                                  enabled.value = false;
                                  try {
                                    final controller = ref.watch(
                                      RoomChatController.provider((
                                        roomId: event.roomId,
                                        contextualEvent: null,
                                        threadRoot: null,
                                      )).notifier,
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
      },
    );
  }
}
