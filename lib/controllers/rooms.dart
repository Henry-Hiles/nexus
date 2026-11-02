import "dart:async";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room.dart";

class RoomsController extends Notifier<IMap<String, Room>> {
  @override
  IMap<String, Room> build() => .new();

  void addState(String roomId, IList<Event> state, {bool isMembers = false}) =>
      update(
        .new({
          roomId: stateRoom(state)
              .copyWith(hasFetchedState: true, hasFetchedMembers: isMembers),
        }),
        .new(),
      );

  void addSpecificState(Iterable<Event> state) => update(
    .new(
      state
          .groupListsBy((event) => event.roomId)
          .map((roomId, roomState) => .new(roomId, stateRoom(roomState))),
    ),
  );

  static Room stateRoom(Iterable<Event> state) => Room(
    events: .fromEntries(state.map((event) => .new(event.rowId, event))),
    state: .new(
      state
          .groupListsBy((event) => event.type)
          .map(
            (type, group) => .new(
              type,
              .fromEntries(group.map((e) => .new(e.stateKey!, e.rowId))),
            ),
          ),
    ),
  );

  static IMap<String, IList<ReadReceipt>> mergeReceipts(
    IMap<String, IList<ReadReceipt>> existing,
    IMap<String, IList<ReadReceipt>> incoming,
  ) => incoming.isEmpty
      ? existing
      : existing.values.flattened
            .followedBy(incoming.values.flattened)
            .groupListsBy((receipt) => (receipt.userId, receipt.thread))
            .values
            .map(
              (receipts) => receipts.reduce(
                (newest, receipt) => newest.timestamp.isAfter(receipt.timestamp)
                    ? newest
                    : receipt,
              ),
            )
            .groupListsBy((receipt) => receipt.eventId)
            .map((eventId, receipts) => MapEntry(eventId, receipts.toIList()))
            .toIMap();

  /// Adds events to their rooms, without changing the rooms' timelines.
  void storeEvents(Iterable<Event> events) => update(
    .new(
      events
          .groupListsBy((event) => event.roomId)
          .map(
            (roomId, roomEvents) => .new(
              roomId,
              Room(
                // ignore: unused_result - I am using it you donkey
                events: .fromIterable(
                  roomEvents,
                  keyMapper: (event) => event.rowId,
                ),
              ),
            ),
          ),
    ),
  );

  static IMap<String, ISet<int>> addRelations(
    IMap<String, ISet<int>> relations,
    Iterable<Event> events,
  ) => events.fold(
    relations,
    (acc, event) => switch (event.relatesTo) {
      final relatesTo? => acc.update(
        relatesTo,
        (rowIds) => rowIds.add(event.rowId),
        ifAbsent: () => .new([event.rowId]),
      ),
      null => acc,
    },
  );

  /// IDs replace previous ones for the same row, e.g. once a local echo is sent.
  static IMap<String, int> addEventIds(
    IMap<String, int> eventIds,
    IMap<int, Event> existing,
    Iterable<Event> events,
  ) => events.fold(eventIds, (acc, event) {
    final previousId = existing[event.rowId]?.eventId;

    return (previousId != null && previousId != event.eventId
            ? acc.remove(previousId)
            : acc)
        .add(event.eventId, event.rowId);
  });

  void update(
    IMap<String, Room> rooms, [
    ISet<String> leftRooms = const .empty(),
  ]) {
    final merged = rooms.entries.fold(state, (acc, entry) {
      final roomId = entry.key;
      final incoming = entry.value;
      final existing = acc[roomId];

      return acc.add(
        roomId,
        existing?.copyWith(
              hasMore: incoming.hasMore,
              clientSticky: incoming.resetClientSticky
                  ? incoming.clientSticky
                  : (incoming.clientSticky.isEmpty
                            ? existing.clientSticky
                            : existing.clientSticky.addAll(
                                incoming.clientSticky,
                              ))
                        .removeWhere(
                          (rowId) => incoming.timeline.values.contains(rowId),
                        ),
              metadata: incoming.metadata ?? existing.metadata,
              events: incoming.events.isEmpty
                  ? existing.events
                  : existing.events.addAll(incoming.events),
              relations: addRelations(
                existing.relations,
                incoming.events.values,
              ),
              eventIds: addEventIds(
                existing.eventIds,
                existing.events,
                incoming.events.values,
              ),
              state: incoming.state.entries.fold(
                existing.state,
                (previousValue, event) => previousValue.add(
                  event.key,
                  (previousValue[event.key] ?? .new()).addAll(event.value),
                ),
              ),
              resetClientSticky: false,
              reset: false,
              hasFetchedMembers:
                  incoming.hasFetchedMembers || existing.hasFetchedMembers,
              hasFetchedState:
                  incoming.hasFetchedState || existing.hasFetchedState,
              timeline: incoming.reset
                  ? incoming.timeline
                  : existing.timeline.addAll(incoming.timeline),
              receipts: mergeReceipts(existing.receipts, incoming.receipts),
            ) ??
            incoming.copyWith(
              receipts: mergeReceipts(const .empty(), incoming.receipts),
              relations: addRelations(const .empty(), incoming.events.values),
              eventIds: addEventIds(
                const .empty(),
                const .empty(),
                incoming.events.values,
              ),
            ),
      );
    });

    state = leftRooms.fold(merged, (acc, roomId) => acc.remove(roomId));
  }

  /// Waits for a sent state event to become the room's state, which happens
  /// once it comes down sync. Gives up after a while, e.g. if another event
  /// replaced it first.
  Future<void> awaitState(
    String roomId,
    String type,
    String eventId, {
    String stateKey = "",
  }) => awaitRooms(
    (rooms) => switch (rooms[roomId]?.state[type]?[stateKey]) {
      final rowId? => rooms[roomId]?.events[rowId]?.eventId == eventId,
      null => false,
    },
  );

  /// Waits for a sent event to come down sync, giving up after a while.
  Future<void> awaitEvent(String roomId, String eventId) => awaitRooms(
    (rooms) => rooms[roomId]?.eventIds.containsKey(eventId) ?? false,
  );

  Future<void> awaitRooms(bool Function(IMap<String, Room> rooms) arrived) {
    if (arrived(state)) return .value();

    final completer = Completer<void>();
    final removeListener = listenSelf((_, rooms) {
      if (arrived(rooms) && !completer.isCompleted) completer.complete();
    });
    return completer.future
        .timeout(const .new(seconds: 10), onTimeout: () {})
        .whenComplete(removeListener);
  }

  static final provider = NotifierProvider<RoomsController, IMap<String, Room>>(
    RoomsController.new,
  );
}
