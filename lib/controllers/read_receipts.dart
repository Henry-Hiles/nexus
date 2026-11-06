import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/is_shown_as_message.dart";
import "package:nexus/models/read_receipt.dart";

/// Other users' read receipts in a chat, by the event ID of the message to
/// show them under: the nearest message at or before what they've read.
class ReadReceiptsController(final ChatParams chat)
    extends Notifier<IMap<String, IList<ReadReceipt>>> {
  @override
  IMap<String, IList<ReadReceipt>> build() {
    final shouldShow = ref.watch(
      SettingsController.provider.select(
        (settings) => settings.value?.readReceipts != .neither,
      ),
    );
    if (!shouldShow) return const .empty();

    final userId = ref.watch(
      ClientStateController.provider.select((state) => state?.userId),
    );
    // The chat's own timeline, so receipts follow what's actually shown
    final timeline = ref.watch(
      RoomChatController.provider(chat)
          .select((roomChat) => roomChat.value?.timeline),
    );
    final room = ref.watch(
      RoomsController.provider.select(
        (rooms) => switch (rooms[chat.roomId]) {
          final room? => (
            events: room.events,
            eventIds: room.eventIds,
            receipts: room.receipts,
            timeline: room.timeline,
          ),
          null => null,
        },
      ),
    );
    if (userId == null || timeline == null || room == null) {
      return const .empty();
    }

    final events = timeline.map((rowId) => room.events[rowId]).nonNulls;
    final indexes = IMap.fromEntries(
      events.indexed.map((entry) => MapEntry(entry.$2.eventId, entry.$1)),
    );
    final messages = events.indexed
        .where((entry) => entry.$2.isShownAsMessage)
        .toIList();
    final messageIndexes = messages.map((entry) => entry.$1).toList();

    final positions = IMap.fromEntries(
      room.timeline.entries
          .map(
            (entry) => switch (entry.value) {
              final rowId? => MapEntry(rowId, entry.key),
              null => null,
            },
          )
          .nonNulls,
    );
    final placed = events.indexed
        .map(
          (entry) => switch (positions[entry.$2.rowId]) {
            final position? => (index: entry.$1, position: position),
            null => null,
          },
        )
        .nonNulls
        .toList();
    final placedPositions = placed.map((entry) => entry.position).toList();

    int? indexOf(String eventId) {
      if (indexes[eventId] case final index?) return index;

      final position = switch (room.eventIds[eventId]) {
        final rowId? => positions[rowId],
        null => null,
      };
      if (position == null) return null;

      final before = lowerBound(placedPositions, position + 1) - 1;
      return before < 0 ? null : placed[before].index;
    }

    return room.receipts.values.flattened
        .where(
          (receipt) =>
              receipt.userId != userId &&
              receipt.thread == (chat.threadRoot ?? "main"),
        )
        .map(
          (receipt) => switch (indexOf(receipt.eventId)) {
            final index? => (
              receipt: receipt,
              message: lowerBound(messageIndexes, index + 1) - 1,
            ),
            null => null,
          },
        )
        .nonNulls
        .where((entry) => entry.message >= 0)
        .groupListsBy((entry) => messages[entry.message].$2.eventId)
        .map(
          (eventId, entries) => MapEntry(
            eventId,
            entries
                .map((entry) => entry.receipt)
                .sorted((a, b) => b.timestamp.compareTo(a.timestamp))
                .toIList(),
          ),
        )
        .toIMap();
  }

  static final provider = NotifierProvider.family
      .autoDispose<
        ReadReceiptsController,
        IMap<String, IList<ReadReceipt>>,
        ChatParams
      >(ReadReceiptsController.new);
}
