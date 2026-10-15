import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/models/requests/join_room.dart";

extension JoinRoom on BuildContext {
  /// Joins a room, showing progress, success (with a button to open the room)
  /// and errors in snackbars.
  ///
  /// Returns the joined room's ID, or null if joining failed.
  Future<String?> joinRoom(
    JoinRoomRequest request, {
    required String name,
  }) async {
    final container = ProviderScope.containerOf(this);
    final messenger = ScaffoldMessenger.of(this);
    final colorScheme = Theme.of(this).colorScheme;

    final joining = messenger.showSnackBar(
      .new(content: Text("Joining $name..."), duration: const .new(days: 1)),
    );

    try {
      final roomId = await container
          .read(ClientController.provider.notifier)
          .joinRoom(request);

      joining.close();
      messenger.showSnackBar(
        .new(
          content: Text("Joined $name."),
          action: .new(
            label: "Open",
            onPressed: () async {
              if (await container.focusRoom(roomId)) {
                container
                    .read(SidebarPageController.provider.notifier)
                    .set(.rooms);
              } else {
                messenger.showSnackBar(
                  .new(
                    content: Text(
                      "$name hasn't finished syncing yet, try again in a moment.",
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );

      return roomId;
    } catch (error) {
      joining.close();
      messenger.showSnackBar(
        .new(
          backgroundColor: colorScheme.errorContainer,
          content: Text(
            error.toString(),
            style: .new(color: colorScheme.onErrorContainer),
          ),
        ),
      );

      return null;
    }
  }
}
