import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/selected_space_controller.dart";
import "package:nexus/models/room.dart";

class SelectedRoomController extends Notifier<Room?> {
  @override
  Room? build() {
    final space = ref.watch(SelectedSpaceController.provider);
    final selectedRoomId = ref.watch(
      KeyController.provider(KeyController.roomKey),
    );

    return space.children.firstWhereOrNull(
          (room) => room.metadata?.id == selectedRoomId,
        ) ??
        space.children.firstOrNull;
  }

  static final provider = NotifierProvider<SelectedRoomController, Room?>(
    SelectedRoomController.new,
  );
}
