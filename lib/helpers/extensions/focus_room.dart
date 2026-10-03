import "package:collection/collection.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:nexus/controllers/jump_request.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/models/space.dart";

extension FocusRoom on MutationTarget {
  Future<bool> focusRoom(String roomId, [int? eventRowId]) async {
    final spaces = await container.read(SpacesController.provider.future);

    if (spaces.firstWhereOrNull((space) => space.id == roomId) case Space _?) {
      await container
          .read(KeyController.provider(KeyController.spaceKey).notifier)
          .set(roomId);
      return true;
    }

    final parent = spaces.firstWhereOrNull(
      (space) =>
          space.children.any((room) => room.metadata?.id == roomId) ||
          space.subSpaces.any(
            (sub) =>
                sub.room.metadata?.id == roomId ||
                sub.children.any((room) => room.metadata?.id == roomId),
          ),
    );
    if (parent == null) return false;

    await container
        .read(KeyController.provider(KeyController.spaceKey).notifier)
        .set(parent.id);

    if (eventRowId != null) {
      container
          .read(JumpRequestController.provider.notifier)
          .request(roomId, eventRowId);
    }

    await container
        .read(KeyController.provider(KeyController.roomKey).notifier)
        .set(roomId);

    return true;
  }
}
