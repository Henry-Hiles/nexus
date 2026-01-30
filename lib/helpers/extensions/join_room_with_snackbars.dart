import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/models/requests/join_room_request.dart";

extension JoinRoomWithSnackbars on ClientController {
  Future<void> joinRoomWithSnackBars(
    BuildContext context,
    String roomAlias,
    WidgetRef ref,
  ) async {
    final roomIdOrAlias = roomAlias.mention ?? roomAlias;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final snackbar = scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text("Joining room $roomIdOrAlias."),
        duration: Duration(days: 999),
      ),
    );

    try {
      final id = await joinRoom(
        JoinRoomRequest(
          roomIdOrAlias: roomIdOrAlias,
          via: IList(Uri.tryParse(roomAlias)?.queryParametersAll["via"] ?? []),
        ),
      );

      snackbar.close();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Room $roomIdOrAlias successfully joined."),
          action: SnackBarAction(
            label: "Open",
            onPressed: () async {
              final spaces = ref.watch(SpacesController.provider);
              final space = spaces.firstWhereOrNull((space) => space.id == id);

              await ref
                  .watch(
                    KeyController.provider(KeyController.spaceKey).notifier,
                  )
                  .set(
                    space?.id ??
                        spaces
                            .firstWhere(
                              (space) => space.children.any(
                                (child) => child.metadata?.id == id,
                              ),
                            )
                            .id,
                  );

              if (space == null) {
                await ref
                    .watch(
                      KeyController.provider(KeyController.roomKey).notifier,
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
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              error.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        );
      }
    }
  }
}
