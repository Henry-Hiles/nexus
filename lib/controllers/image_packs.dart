import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/image_pack_sources.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/event.dart";
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
          final room = rooms[source.roomId];
          if (room == null) return const <ImagePack>[];

          final newPacks = room.state[EventType.imagePack.type];
          final legacyPacks = room.state[EventType.legacyImagePack.type];
          final roomName = room.metadata?.name ?? source.roomId;

          return switch (source.stateKey) {
                final stateKey? => ISet([stateKey]),
                null => ISet(
                  newPacks?.keys ?? const <String>[],
                ).addAll(legacyPacks?.keys ?? const []),
              }
              .map(
                (stateKey) =>
                    switch (newPacks?[stateKey] ?? legacyPacks?[stateKey]) {
                      final rowId? => switch (room.events[rowId]) {
                        Event(
                          redactedBy: null,
                          content: final ImagePackContent content,
                        ) =>
                          ImagePack.fromContent(
                            content,
                            id: "${source.roomId}/$stateKey",
                            fallbackName: stateKey.isEmpty
                                ? roomName
                                : "$roomName - $stateKey",
                          ),
                        _ => null,
                      },
                      null => null,
                    },
              )
              .nonNulls;
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
