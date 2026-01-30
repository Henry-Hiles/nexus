import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

class MembersController extends AsyncNotifier<IList<Event>> {
  final Room room;
  MembersController(this.room);

  @override
  Future<IList<Event>> build() async =>
      (room.state["m.room.member"]?.values ?? [])
          .map(
            (eventRowId) => room.events.firstWhereOrNull(
              (event) => event.rowId == eventRowId,
            ),
          )
          .nonNulls
          .toIList();

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MembersController, IList<Event>, Room>(
        MembersController.new,
      );
}
