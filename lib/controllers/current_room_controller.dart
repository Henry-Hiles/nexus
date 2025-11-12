import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/models/full_room.dart";

class CurrentRoomController extends AsyncNotifier<FullRoom> {
  @override
  Future<FullRoom> build() async => (await ref.watch(
    SpacesController.provider.future,
  ))[0].children[0].roomData.fullRoom;

  void set(FullRoom room) => state = AsyncValue.data(room);

  static final provider =
      AsyncNotifierProvider<CurrentRoomController, FullRoom>(
        CurrentRoomController.new,
      );
}
