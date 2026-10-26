import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/enabled_image_packs.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_edges.dart";

typedef ImagePackSource = ({String roomId, String? stateKey});

class ImagePackSourcesController(final String roomId)
    extends AsyncNotifier<IList<ImagePackSource>> {
  @override
  Future<IList<ImagePackSource>> build() async {
    final enabledPacksFuture = ref.watch(
      EnabledImagePacksController.provider.future,
    );
    final spaceEdges = ref.watch(SpaceEdgesController.provider);
    final directParents = ref.watch(
      RoomsController.provider.select(
        (rooms) =>
            rooms[roomId]?.state["m.space.parent"]?.keys.toISet() ??
            const .empty(),
      ),
    );

    Iterable<String> parentsOf(String childId) => spaceEdges.entries
        .where((entry) => entry.value.any((edge) => edge.childId == childId))
        .map((entry) => entry.key)
        .followedBy(childId == roomId ? directParents : const []);

    ISet<String> withAncestors(ISet<String> spaces, String childId) =>
        parentsOf(childId).fold(
          spaces,
          (spaces, parentId) => spaces.contains(parentId)
              ? spaces
              : withAncestors(spaces.add(parentId), parentId),
        );

    final rooms = ref.read(RoomsController.provider);
    final spaces = withAncestors(
      const .empty(),
      roomId,
    ).remove(roomId).where(rooms.containsKey).toIList();

    final client = ref.read(ClientController.provider.notifier);
    final roomsNotifier = ref.read(RoomsController.provider.notifier);

    await Future.wait(
      spaces
          .where((spaceId) => !rooms[spaceId]!.hasFetchedState)
          .map(
            (spaceId) async => roomsNotifier.addState(
              spaceId,
              await client.getRoomState(.new(roomId: spaceId)),
            ),
          ),
    );
    final enabledPacks = await enabledPacksFuture;

    return .new([
      (roomId: roomId, stateKey: null),
      ...spaces.map((spaceId) => (roomId: spaceId, stateKey: null)),
      ...enabledPacks.entries.expand(
        (entry) => entry.value.map(
          (stateKey) => (roomId: entry.key, stateKey: stateKey),
        ),
      ),
    ]);
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<ImagePackSourcesController, IList<ImagePackSource>, String>(
        ImagePackSourcesController.new,
      );
}
