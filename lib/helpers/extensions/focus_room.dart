import "package:collection/collection.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/models/space.dart";

extension FocusRoom on MutationTarget {
  Future<bool> focusRoom(String id) async {
    final spaces = container.read(SpacesController.provider);

    if (spaces.firstWhereOrNull((space) => space.id == id) case Space _?) {
      await container
          .read(KeyController.provider(KeyController.spaceKey).notifier)
          .set(id);
      return true;
    }

    final parent = spaces.firstWhereOrNull(
      (space) =>
          space.children.any((room) => room.metadata?.id == id) ||
          space.subSpaces.any(
            (sub) =>
                sub.room.metadata?.id == id ||
                sub.children.any((room) => room.metadata?.id == id),
          ),
    );
    if (parent == null) return false;

    await container
        .read(KeyController.provider(KeyController.spaceKey).notifier)
        .set(parent.id);

    await container
        .read(KeyController.provider(KeyController.roomKey).notifier)
        .set(id);

    return true;
  }
}
