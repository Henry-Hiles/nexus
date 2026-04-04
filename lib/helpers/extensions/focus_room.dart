import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";

extension FocusRoom on WidgetRef {
  Future<void> focusRoom(String id) async {
    final spaces = watch(SpacesController.provider);
    final space = spaces.firstWhereOrNull((space) => space.id == id);

    await watch(KeyController.provider(KeyController.spaceKey).notifier).set(
      space?.id ??
          spaces
              .firstWhere(
                (space) =>
                    space.children.any((child) => child.metadata?.id == id),
              )
              .id,
    );

    if (space == null) {
      await watch(
        KeyController.provider(KeyController.roomKey).notifier,
      ).set(id);
    }
  }
}
