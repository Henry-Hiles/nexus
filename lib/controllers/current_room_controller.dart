import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/models/full_room.dart";

class CurrentRoomController extends AsyncNotifier<FullRoom?> {
  @override
  Future<FullRoom?> build() async {
    final spaces = await ref.watch(SpacesController.provider.future);

    if (spaces.isEmpty || spaces[0].children.isEmpty) return null;
    return spaces[0].children[0].roomData.fullRoom;
  }

  Future<void> set(FullRoom room) async {
    await future;
    state = AsyncValue.data(room);
  }

  static final provider =
      AsyncNotifierProvider<CurrentRoomController, FullRoom?>(
        CurrentRoomController.new,
      );
}
