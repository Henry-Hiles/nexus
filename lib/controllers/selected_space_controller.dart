import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/models/space.dart";

class SelectedSpaceController extends AsyncNotifier<Space> {
  @override
  Future<Space> build() async {
    final spaces = await ref.watch(
      SpacesController.provider.selectAsync((data) => data),
    );
    final selectedSpaceId = ref.watch(
      KeyController.provider(KeyController.spaceKey),
    );

    return spaces.firstWhereOrNull((space) => space.id == selectedSpaceId) ??
        spaces.first;
  }

  static final provider = AsyncNotifierProvider<SelectedSpaceController, Space>(
    SelectedSpaceController.new,
  );
}
