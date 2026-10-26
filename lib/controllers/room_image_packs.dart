import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/room_image_packs.dart";
import "package:nexus/models/image_pack.dart";

/// The image packs in [roomId]'s own state by state key, loading its state if
/// it hasn't been yet.
class RoomImagePacksController(final String roomId)
    extends AsyncNotifier<IMap<String, ImagePack>> {
  @override
  Future<IMap<String, ImagePack>> build() async {
    if (ref.read(RoomsController.provider)[roomId] case final room?
        when !room.hasFetchedState) {
      ref
          .read(RoomsController.provider.notifier)
          .addState(
            roomId,
            await ref
                .read(ClientController.provider.notifier)
                .getRoomState(.new(roomId: roomId)),
          );
    }

    return ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms[roomId]?.imagePacks(roomId) ?? const .empty(),
      ),
    );
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<RoomImagePacksController, IMap<String, ImagePack>, String>(
        RoomImagePacksController.new,
      );
}
