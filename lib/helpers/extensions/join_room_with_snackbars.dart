import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";

extension JoinRoomWithSnackbars on Client {
  Future<void> joinRoomWithSnackBars(
    BuildContext context,
    String roomAlias,
    WidgetRef ref,
  ) async {
    final parsed = roomAlias.parseIdentifierIntoParts();
    final alias = parsed?.primaryIdentifier ?? roomAlias;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final snackbar = scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text("Joining room $alias."),
        duration: Duration(days: 999),
      ),
    );

    try {
      final id = await joinRoom(alias, via: parsed?.via.toList());

      snackbar.close();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Room $alias successfully joined."),
          action: SnackBarAction(
            label: "Open",
            onPressed: () async {
              final spaces = await ref.refresh(
                SpacesController.provider.future,
              );
              final space = spaces.firstWhereOrNull((space) => space.id == id);

              await ref
                  .watch(
                    KeyController.provider(KeyController.spaceKey).notifier,
                  )
                  .set(
                    space?.id ??
                        spaces
                            .firstWhere(
                              (space) =>
                                  space.children.firstWhereOrNull(
                                    (child) => child.roomData.id == id,
                                  ) !=
                                  null,
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
