import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/space_edge.dart";
import "package:nexus/models/sync_data.dart";

class SpaceEdgesController extends Notifier<IMap<String, IList<SpaceEdge>>> {
  @override
  IMap<String, IList<SpaceEdge>> build() => .new();

  void handleSync(SyncData sync) {
    if (sync.clearState) state = .new();
    state = state.addAll(sync.spaceEdges ?? const .empty());
  }

  static final provider =
      NotifierProvider<SpaceEdgesController, IMap<String, IList<SpaceEdge>>>(
        SpaceEdgesController.new,
      );
}
