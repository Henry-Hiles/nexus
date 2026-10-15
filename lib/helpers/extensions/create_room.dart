import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/models/requests/create_room.dart";

extension CreateRoom on BuildContext {
  /// Creates a room, showing progress and errors in snackbars, and opens it
  /// once it has synced. [request] may be a future, so any lookups needed to
  /// build it happen while the progress snackbar is shown.
  ///
  /// Returns the created room's ID, or null if creating it failed.
  Future<String?> createRoom(
    CreateRoomRequest request, {
    required String name,
  }) async {
    final container = ProviderScope.containerOf(this);
    final messenger = ScaffoldMessenger.of(this);

    final result = await withProgressSnackbar("Creating $name...", () async {
      final roomId = await container
          .read(ClientController.provider.notifier)
          .createRoom(request);

      // Wait for the room to show up in the room list (under DMs, if it's
      // one) before opening it.
      final synced = Completer<bool>();
      final subscription = container.listen(
        SpacesController.provider.select(
          (async) =>
              async.value?.any(
                (space) =>
                    space.id == roomId ||
                    ((!request.isDirect || space.id == "dms") &&
                        space.allChildRooms.any(
                          (room) => room.metadata?.id == roomId,
                        )),
              ) ??
              false,
        ),
        (_, found) {
          if (found && !synced.isCompleted) synced.complete(true);
        },
        fireImmediately: true,
      );

      return (
        roomId,
        await synced.future
            .timeout(const .new(seconds: 15), onTimeout: () => false)
            .whenComplete(subscription.close),
      );
    });
    if (result == null) return null;

    final (roomId, synced) = result;
    if (synced && await container.focusRoom(roomId)) {
      container.read(SidebarPageController.provider.notifier).set(.rooms);
    } else {
      messenger.showSnackBar(
        .new(
          content: Text("Created $name, but it hasn't finished syncing yet."),
        ),
      );
    }

    return roomId;
  }

  /// Opens the existing DM with [userId], or creates one if there isn't one.
  Future<void> startDirectMessage(
    String userId, {
    required String name,
    bool encrypted = true,
    String? inviteReason,
  }) async {
    final container = ProviderScope.containerOf(this);
    final existing = container
        .read(RoomsController.provider)
        .values
        .firstWhereOrNull((room) => room.metadata?.dmUserId == userId)
        ?.metadata
        ?.id;

    if (existing != null) {
      if (await container.focusRoom(existing)) {
        container.read(SidebarPageController.provider.notifier).set(.rooms);
      }
      return;
    }

    await createRoom(
      .new(
        isDirect: true,
        preset: .trustedPrivateChat,
        invite: .new([userId]),
        inviteReason: inviteReason,
        initialState: encrypted ? .new([.encryption]) : const .empty(),
      ),
      name: "a DM with $name",
    );
  }
}
