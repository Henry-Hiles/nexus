import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
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

    final roomId = await withProgressSnackbar(
      "Joining $name...",
      () =>
          container.read(ClientController.provider.notifier).joinRoom(request),
    );
    if (roomId == null) return null;

    messenger.showSnackBar(
      .new(
        content: Text("Joined $name."),
        action: .new(
          label: "Open",
          onPressed: () async {
            await container.focusRoom(roomId);
            container.read(SidebarPageController.provider.notifier).set(.rooms);
          },
        ),
      ),
    );

    return roomId;
  }
}
