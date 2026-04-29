import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room.dart";

class RoomsController extends Notifier<IMap<String, Room>> {
  @override
  IMap<String, Room> build() => const IMap.empty();

  void update(
    IMap<String, Room> rooms,
    ISet<String> leftRooms, {
    bool addToNewEvents = true,
  }) {
    final homeserver =
        ref.watch(
          ClientStateController.provider.select(
            (value) => value?.homeserverUrl,
          ),
        ) ??
        "";
    final merged = rooms.entries.fold(state, (acc, entry) {
      final roomId = entry.key;
      final incoming = entry.value;
      final existing = acc[roomId];

      final events = existing?.events.updateById(
        incoming.events,
        (item) => item.eventId,
      );

      if (addToNewEvents) {
        final provider = RoomChatController.provider(roomId);
        if (ref.exists(provider)) {
          for (final event
              in incoming.timeline
                  .map(
                    (timelineTuple) => events?.firstWhereOrNull(
                      (event) => timelineTuple.eventRowId == event.rowId,
                    ),
                  )
                  .nonNulls
                  .toIList()) {
            ref.read(provider.notifier).addEvent(event);
          }
        }
      }

      return acc.add(
        roomId,
        existing?.copyWith(
              hasMore: incoming.hasMore,
              metadata:
                  incoming.metadata?.copyWith(
                    avatar:
                        incoming.metadata?.avatar?.mxcToHttps(homeserver) ??
                        existing.metadata?.avatar,
                  ) ??
                  existing.metadata,
              events: events!,
              state: incoming.state.entries.fold(
                existing.state,
                (previousValue, event) => previousValue.add(
                  event.key,
                  (previousValue[event.key] ?? const IMap.empty()).addAll(
                    event.value,
                  ),
                ),
              ),
              timeline:
                  (incoming.reset
                          ? incoming.timeline
                          : existing.timeline.updateById(
                              incoming.timeline,
                              (item) => item.timelineRowId,
                            ))
                      .sortedBy((element) => element.timelineRowId)
                      .toIList(),
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
            incoming.copyWith(
              metadata: incoming.metadata?.copyWith(
                avatar: incoming.metadata?.avatar?.mxcToHttps(homeserver),
              ),
            ),
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
