import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/selected_space_controller.dart";
import "package:nexus/models/full_room.dart";

class SelectedRoomController extends AsyncNotifier<FullRoom?> {
  @override
  bool updateShouldNotify(
    AsyncValue<FullRoom?> previous,
    AsyncValue<FullRoom?> next,
  ) =>
      previous.value?.avatar != next.value?.avatar ||
      previous.value?.title != next.value?.title;

  @override
  Future<FullRoom?> build() async {
    final space = await ref.watch(SelectedSpaceController.provider.future);
    final selectedRoomId = ref.watch(
      KeyController.provider(KeyController.roomKey),
    );

    return space.children.firstWhereOrNull(
          (room) => room.roomData.id == selectedRoomId,
        ) ??
        space.children.firstOrNull;
  }

  static final provider =
      AsyncNotifierProvider<SelectedRoomController, FullRoom?>(
        SelectedRoomController.new,
      );
}
