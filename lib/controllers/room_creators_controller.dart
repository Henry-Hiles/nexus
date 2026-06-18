import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/room.dart";

class RoomCreatorsController extends Notifier<IList<String>> {
  final Room room;
  RoomCreatorsController(this.room);

  @override
  IList<String> build() {
    final createRowId = room.state[EventType.create.type]?[""];
    final createEvent = createRowId == null ? null : room.events[createRowId];

    if (createEvent == null) return .new();

    final createEventContent = switch (createEvent.content) {
      CreateContent content => content,
      _ => null,
    };

    return switch (createEventContent?.additionalCreatorIds) {
      IList<String> creators => creators.add(createEvent.sender),
      _ => .new([createEvent.sender]),
    };
  }

  static final provider =
      NotifierProvider.family<RoomCreatorsController, IList<String>, Room>(
        RoomCreatorsController.new,
      );
}
