import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/new_events_controller.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room.dart";

class RoomsController extends Notifier<IMap<String, Room>> {
  @override
  IMap<String, Room> build() => const IMap.empty();

  void update(IMap<String, Room> rooms, ISet<String> leftRooms) {
    final merged = rooms.entries.fold(state, (acc, entry) {
      final roomId = entry.key;
      final incoming = entry.value;
      final existing = acc[roomId];

      ref
          .watch(NewEventsController.provider(roomId).notifier)
          .add(incoming.events);

      return acc.add(
        roomId,
        existing?.copyWith(
              metadata: incoming.metadata ?? existing.metadata,
              events: existing.events.updateById(
                incoming.events,
                (item) => item.eventId,
              ),
              state: incoming.state.entries.fold(
                existing.state,
                (stateAcc, event) => stateAcc.add(
                  event.key,
                  (stateAcc[event.key] ?? IMap<dynamic, dynamic>()).addAll(
                    event.value,
                  ),
                ),
              ),
              timeline: incoming.reset
                  ? incoming.timeline
                  : existing.timeline.addAll(incoming.timeline),
              receipts: incoming.receipts.entries.fold(
                existing.receipts,
                (receiptAcc, event) => receiptAcc.add(
                  event.key,
                  (receiptAcc[event.key] ?? IList<ReadReceipt>()).addAll(
                    event.value,
                  ),
                ),
              ),
            ) ??
            incoming,
      );
    });

    final prunedList = leftRooms.fold(
      merged,
      (acc, roomId) => acc.remove(roomId),
    );
    state = prunedList;
  }

  static final provider = NotifierProvider<RoomsController, IMap<String, Room>>(
    RoomsController.new,
  );
}
