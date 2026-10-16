import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/models/space.dart";

class SelectedSpaceController extends Notifier<Space?> {
  @override
  Space? build() {
    final spaces = ref.watch(SpacesController.provider).value;
    if (spaces == null) return null;

    final spaceId = ref.watch(
      KeyController.provider(KeyController.spaceKey)
          .select((async) => async.value),
    );

    return spaces.firstWhereOrNull((space) => space.id == spaceId) ??
        spaces.firstOrNull;
  }

  static final provider = NotifierProvider<SelectedSpaceController, Space?>(
    SelectedSpaceController.new,
  );
}
