import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/reactions.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/main.dart";

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
        AsyncData(value: final reactions) ||
        AsyncLoading(value: final reactions?) => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: reactions
              .where((_, value) => value.isNotEmpty)
              .mapTo(
                (reaction, reactors) => HookBuilder(
                  builder: (context) {
                    final enabled = useState(true);

                    final selected = reactors.contains(clientState!.userId);
                    return Tooltip(
                      message: reactors.join(", "),
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
                                      image: MxcImage(
                                        ref,
                                        .new(mxc: Uri.parse(reaction)),
                                      ),
                                    )
                                  : Text(reaction, overflow: .ellipsis),
                            ),
                            Text(
                              reactors.length.toString(),
                              overflow: .ellipsis,
                            ),
                          ],
                        ),
                        onSelected: enabled.value
                            ? (value) async {
                                enabled.value = false;
                                try {
                                  final controller = ref.watch(
                                    RoomChatController.provider((
                                      event.roomId,
                                      null,
                                    )).notifier,
                                  );

                                  if (selected) {
                                    await controller
                                        .removeReaction(
                                          reaction,
                                          event,
                                          clientState.userId!,
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

        _ => SizedBox.shrink(),
      },
    );
  }
}
