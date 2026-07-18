import "dart:isolate";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

class RoomsController extends Notifier<IMap<String, Room>> {
  @override
  IMap<String, Room> build() => .new();

  Future<void> addState(
    String roomId,
    IList<Event> state, {
    bool isMembers = false,
  }) async => update(
    .new({
      roomId: Room(
        events: .fromEntries(state.map((event) => .new(event.rowId, event))),
        hasFetchedState: true,
        hasFetchedMembers: isMembers,
        state: await Isolate.run(() {
          final newState = state.fold<IMap<String, IMap<String, int>>>(
            .new(),
            (previousValue, stateEvent) => previousValue.add(
              stateEvent.type,
              (previousValue[stateEvent.type] ?? .new()).add(
                stateEvent.stateKey!,
                stateEvent.rowId,
              ),
            ),
          );
          return newState;
        }),
      ),
    }),
    .new(),
  );

  void update(IMap<String, Room> rooms, ISet<String> leftRooms) {
    final merged = rooms.entries.fold(state, (acc, entry) {
      final roomId = entry.key;
      final incoming = entry.value;
      final existing = acc[roomId];

      return acc.add(
        roomId,
        existing?.copyWith(
              hasMore: incoming.hasMore,
              sticky:
                  (incoming.sticky.isEmpty == true
                          ? existing.sticky
                          : existing.sticky.addAll(incoming.sticky))
                      .removeWhere(
                        (rowId) => incoming.timeline.values.contains(rowId),
                      ),
              metadata: incoming.metadata ?? existing.metadata,
              events: incoming.events.isEmpty
                  ? existing.events
                  : existing.events.addAll(incoming.events),
              state: incoming.state.entries.fold(
                existing.state,
                (previousValue, event) => previousValue.add(
                  event.key,
                  (previousValue[event.key] ?? .new()).addAll(event.value),
                ),
              ),
              reset: false,
              hasFetchedMembers:
                  incoming.hasFetchedMembers || existing.hasFetchedMembers,
              hasFetchedState:
                  incoming.hasFetchedState || existing.hasFetchedState,
              timeline: (incoming.reset
                  ? incoming.timeline
                  : existing.timeline.addAll(incoming.timeline)),
              receipts: incoming.receipts.entries.fold(
                existing.receipts,
                (receiptAcc, event) => receiptAcc.add(
                  event.key,
                  (receiptAcc[event.key] ?? .new()).addAll(event.value),
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
