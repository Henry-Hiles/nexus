import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";

class JoinDialog extends HookWidget {
  final WidgetRef ref;
  const JoinDialog(this.ref, {super.key});

  @override
  Widget build(BuildContext context) {
    final roomAlias = useTextEditingController();
    return AlertDialog(
      title: Text("Join a Room"),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text("Enter the room alias, Matrix URI, or Matrix.to link."),
          SizedBox(height: 12),
          TextField(
            controller: roomAlias,
            decoration: .new(hintText: "#room:server"),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            if (context.mounted) {
              final roomIdOrAlias = roomAlias.text.mention ?? roomAlias.text;

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final snackbar = scaffoldMessenger.showSnackBar(
                .new(
                  content: Text("Joining room $roomIdOrAlias."),
                  duration: Duration(days: 999),
                ),
              );

              try {
                final id = await ref
                    .watch(ClientController.provider.notifier)
                    .joinRoom(
                      .new(
                        roomIdOrAlias: roomIdOrAlias,
                        via: .new(
                          Uri.tryParse(
                                roomAlias.text.replaceAll("/#", ""),
                              )?.queryParametersAll["via"] ??
                              [],
                        ),
                      ),
                    );

                snackbar.close();

                scaffoldMessenger.showSnackBar(
                  .new(
                    content: Text("Room $roomIdOrAlias successfully joined."),
                    action: .new(
                      label: "Open",
                      onPressed: () async {
                        final spaces = ref.watch(SpacesController.provider);
                        final space = spaces.firstWhereOrNull(
                          (space) => space.id == id,
                        );

                        await ref
                            .watch(
                              KeyController.provider(
                                KeyController.spaceKey,
                              ).notifier,
                            )
                            .set(
                              space?.id ??
                                  spaces
                                      .firstWhere(
                                        (space) =>
                                            space.children.any(
                                              (child) =>
                                                  child.metadata?.id == id,
                                            ) ||
                                            space.subSpaces.any(
                                              (child) =>
                                                  child.room.metadata?.id == id,
                                            ),
                                      )
                                      .id,
                            );

                        if (space == null) {
                          await ref
                              .watch(
                                KeyController.provider(
                                  KeyController.roomKey,
                                ).notifier,
                              )
                              .set(id);
                        }
                      },
                    ),
                  ),
                );
              } catch (error) {
                snackbar.close();
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    .new(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      content: Text(
                        error.toString(),
                        style: .new(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: Text("Join"),
        ),
      ],
    );
  }
}
