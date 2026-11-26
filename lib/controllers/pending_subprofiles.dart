import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

typedef PendingSubprofile = ({String id, Future<void> synced});

/// Subprofiles just chosen for rooms, by room ID, until they come down sync.
/// gomuks only learns of them then, so messages sent before would use the
/// previous one.
class PendingSubprofilesController
    extends Notifier<IMap<String, PendingSubprofile>> {
  @override
  IMap<String, PendingSubprofile> build() => const .empty();

  Future<void> track(
    String roomId,
    String id,
    Future<void> Function() save,
  ) async {
    final synced = save();
    state = state.add(roomId, (id: id, synced: synced));

    try {
      await synced;
    } finally {
      // Unless another subprofile was chosen meanwhile
      if (state[roomId]?.synced == synced) state = state.remove(roomId);
    }
  }

  Future<void> settled(String roomId) async {
    try {
      await state[roomId]?.synced;
    } catch (_) {
      throw Exception(
        "The message wasn't sent, as the subprofile chosen for this room couldn't be saved",
      );
    }
  }

  static final provider =
      NotifierProvider<
        PendingSubprofilesController,
        IMap<String, PendingSubprofile>
      >(PendingSubprofilesController.new);
}
