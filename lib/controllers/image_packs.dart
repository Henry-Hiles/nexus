import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/image_pack_sources.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/room_image_packs.dart";
import "package:nexus/models/image_pack.dart";

class ImagePacksController(final String roomId)
    extends AsyncNotifier<IList<ImagePack>> {
  @override
  Future<IList<ImagePack>> build() async {
    final sources = await ref.watch(
      ImagePackSourcesController.provider(roomId).future,
    );

    final packs = ref.watch(
      RoomsController.provider.select(
        (rooms) => sources.expand((source) {
          final packs =
              rooms[source.roomId]?.imagePacks(source.roomId) ?? const .empty();

          return switch (source.stateKey) {
            final stateKey? => [?packs[stateKey]],
            null => packs.values,
          };
        }).toIList(),
      ),
    );

    return .new(
      packs
          .whereNoDuplicates(by: (pack) => pack.id)
          .where(
            (pack) => pack.emoticons.isNotEmpty || pack.stickers.isNotEmpty,
          ),
    );
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<ImagePacksController, IList<ImagePack>, String>(
        ImagePacksController.new,
      );
}
