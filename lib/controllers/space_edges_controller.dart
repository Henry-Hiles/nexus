import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/space_edge.dart";

class SpaceEdgesController extends Notifier<IMap<String, IList<SpaceEdge>>> {
  @override
  IMap<String, IList<SpaceEdge>> build() => const IMap.empty();

  void set(IMap<String, IList<SpaceEdge>> newEdges) => state = newEdges;

  static final provider =
      NotifierProvider<SpaceEdgesController, IMap<String, IList<SpaceEdge>>>(
        SpaceEdgesController.new,
      );
}
