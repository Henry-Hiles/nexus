import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room_power_levels.dart";

class RoomPowerLevelsController(final String roomId)
    extends Notifier<RoomPowerLevels> {
  @override
  RoomPowerLevels build() {
    final room = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]),
    );

    Event? stateEvent(EventType type) => switch (room?.state[type.type]?[""]) {
      final rowId? => room?.events[rowId],
      null => null,
    };

    final createEvent = stateEvent(.create);
    final create = switch (createEvent?.content) {
      final CreateContent content => content,
      _ => null,
    };
    // Creators only outrank everyone from room version 12, earlier ones just have a power level
    final creatorsPrivileged =
        (int.tryParse(create?.roomVersion ?? "") ?? 0) >= 12;

    return .new(
      content: switch (stateEvent(.powerLevels)?.content) {
        final PowerLevelsContent content => content,
        // Until there are power levels, creators have 100
        _ => PowerLevelsContent(
          users: switch (createEvent) {
            final createEvent? when !creatorsPrivileged => .new({
              createEvent.sender: 100,
            }),
            _ => const .empty(),
          },
        ),
      },
      creators: switch (createEvent) {
        final createEvent? when creatorsPrivileged =>
          (create?.additionalCreatorIds ?? const .empty())
              .add(createEvent.sender)
              .toISet(),
        _ => const .empty(),
      },
    );
  }

  static final provider = NotifierProvider.autoDispose
      .family<RoomPowerLevelsController, RoomPowerLevels, String>(
        RoomPowerLevelsController.new,
      );
}
