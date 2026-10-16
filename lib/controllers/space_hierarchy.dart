import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/space_hierarchy.dart";

class SpaceHierarchyController(final String spaceId)
    extends AsyncNotifier<SpaceHierarchy> {
  @override
  Future<SpaceHierarchy> build() => ref
      .read(ClientController.provider.notifier)
      .getSpaceHierarchy(.new(roomId: spaceId, maxDepth: 1));

  Future<void> loadMore() async {
    final current = await future;
    if (current.nextBatch == null) return;

    final next = await ref
        .read(ClientController.provider.notifier)
        .getSpaceHierarchy(
          .new(roomId: spaceId, maxDepth: 1, from: current.nextBatch),
        );

    state = AsyncData(
      current.copyWith(
        rooms: current.rooms.addAll(next.rooms),
        nextBatch: next.nextBatch,
      ),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<SpaceHierarchyController, SpaceHierarchy, String>(
        SpaceHierarchyController.new,
      );
}
