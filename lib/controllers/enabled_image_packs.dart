import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/requests/get_specific_room_state.dart";

/// The image packs the user has enabled everywhere, as room IDs to their
/// packs' state keys, once the packs' state has been loaded.
class EnabledImagePacksController
    extends AsyncNotifier<IMap<String, ISet<String>>> {
  @override
  Future<IMap<String, ISet<String>>> build() async {
    final enabledPacks = ref.watch(
      AccountDataController.provider.select(
        (data) => data.enabledImagePacks.rooms.map(
          (roomId, packs) => .new(roomId, packs.keys.toISet()),
        ),
      ),
    );

    const packTypes = <EventType>[.imagePack, .legacyImagePack];
    // Rooms we aren't in can't be fetched, and fetched rooms have every pack.
    final missingKeys = ref.watch(
      RoomsController.provider.select(
        (rooms) => enabledPacks.entries
            .where((entry) => !(rooms[entry.key]?.hasFetchedState ?? true))
            .expand(
              (entry) => entry.value
                  .where(
                    (stateKey) => packTypes.every(
                      (type) =>
                          rooms[entry.key]?.state[type.type]?[stateKey] == null,
                    ),
                  )
                  .expand(
                    (stateKey) => packTypes.map(
                      (type) => RoomStateKey(
                        roomId: entry.key,
                        type: type.type,
                        stateKey: stateKey,
                      ),
                    ),
                  ),
            )
            .toIList(),
      ),
    );

    if (missingKeys.isNotEmpty) {
      ref
          .read(RoomsController.provider.notifier)
          .addSpecificState(
            await ref
                .read(ClientController.provider.notifier)
                .getSpecificRoomState(.new(keys: missingKeys)),
          );
    }

    return enabledPacks;
  }

  static final provider =
      AsyncNotifierProvider.autoDispose<
        EnabledImagePacksController,
        IMap<String, ISet<String>>
      >(EnabledImagePacksController.new);
}
