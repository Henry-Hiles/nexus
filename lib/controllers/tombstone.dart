import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/event.dart";

class TombstoneController(final String roomId) extends Notifier<Event?> {
  @override
  Event? build() => ref.watch(
    RoomsController.provider.select((rooms) {
      final room = rooms[roomId];
      return switch (room?.state[EventType.tombstone.type]?[""]) {
        final rowId? => room?.events[rowId],
        null => null,
      };
    }),
  );

  static final provider = NotifierProvider.family
      .autoDispose<TombstoneController, Event?, String>(
        TombstoneController.new,
      );
}
