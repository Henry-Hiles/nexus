import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";

class MutualRoomsController(final String userId)
    extends AsyncNotifier<IList<String>> {
  @override
  Future<IList<String>> build() =>
      ref.read(ClientController.provider.notifier).getMutualRooms(userId);

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MutualRoomsController, IList<String>, String>(
        MutualRoomsController.new,
      );
}
