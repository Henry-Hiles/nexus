import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/selected_space.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";

class SelectedRoomController extends Notifier<String?> {
  @override
  String? build() {
    final roomId = ref.watch(
      KeyController.provider(KeyController.roomKey)
          .select((async) => async.value),
    );

    final roomIds = ref.watch(
      SelectedSpaceController.provider.select(
        (space) => space?.allChildRooms
            .map((room) => room.metadata?.id)
            .nonNulls
            .toIList()
            // Real spaces have a timeline of their own
            .addAll([?space.room?.metadata?.id]),
      ),
    );
    if (roomIds == null || roomIds.contains(roomId)) return roomId;

    final fallback = roomIds.firstOrNull;
    Future.microtask(() {
      if (!ref.mounted) return;
      ref
          .read(KeyController.provider(KeyController.roomKey).notifier)
          .set(fallback);
    });
    return fallback;
  }

  static final provider = NotifierProvider<SelectedRoomController, String?>(
    SelectedRoomController.new,
  );
}
