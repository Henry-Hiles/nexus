import "package:flutter_riverpod/experimental/mutation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/room_directory.dart";

/// The public room directory of a server, or of the user's own if null.
class RoomDirectoryController(final String? server)
    extends AsyncNotifier<RoomDirectory> {
  @override
  Future<RoomDirectory> build() => ref
      .read(ClientController.provider.notifier)
      .getRoomDirectory(.new(server: server));

  Future<void> loadMore() async {
    final current = await future;
    if (current.nextBatch == null) return;

    final next = await ref
        .read(ClientController.provider.notifier)
        .getRoomDirectory(.new(server: server, since: current.nextBatch));

    if (!ref.mounted) return;

    state = AsyncData(
      current.copyWith(
        rooms: current.rooms.addAll(next.rooms),
        nextBatch: next.nextBatch,
      ),
    );
  }

  /// Loading the next page of a directory, keyed by its server
  static final loadMoreMutation = Mutation<void>();

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomDirectoryController, RoomDirectory, String?>(
        RoomDirectoryController.new,
      );
}
