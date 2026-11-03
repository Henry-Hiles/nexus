import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";

/// Whether a room is published to the user's server's room directory.
class RoomPublishedController(final String roomId) extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.read(ClientController.provider.notifier).getRoomPublished(roomId);

  Future<void> set(bool published) async {
    await ref
        .read(ClientController.provider.notifier)
        .setRoomPublished(roomId, published);
    ref.invalidateSelf();
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomPublishedController, bool, String>(
        RoomPublishedController.new,
      );
}
