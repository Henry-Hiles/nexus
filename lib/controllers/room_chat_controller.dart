import "dart:async";
import "dart:math";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/reaction.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/redact_event_request.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/send_message_request.dart";
import "package:nexus/models/room.dart";

class RoomChatController extends AsyncNotifier<IList<Event>> {
  final String roomId;
  RoomChatController(this.roomId);

  @override
  Future<IList<Event>> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    final room = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]),
    );
    if (room == null) return .new();

    if (!room.hasFetchedState) {
      final state = await client.getRoomState(.new(roomId: roomId));

      await ref.read(RoomsController.provider.notifier).addState(roomId, state);
    }

    // While there are under 20 events, try to load more
    // until there's no more or the conditions are met.
    if (room.hasMore && room.timeline.length < 20) {
      loadOlder();
    }

    return room.timeline
        .toEntryIList(compare: (a, b) => (a?.key ?? 0).compareTo(b?.key ?? 0))
        .map((element) => element.value)
        .toIList()
        .addAll(room.sticky)
        .map((entry) {
          final foundEvent = entry == null ? null : room.events[entry];

          final editedEvent =
              foundEvent == null || foundEvent.lastEditRowId == 0
              ? null
              : room.events[foundEvent.lastEditRowId];

          return editedEvent == null
              ? foundEvent
              : foundEvent?.copyWith(content: editedEvent.content);
        })
        .nonNulls
        .toIList();
  }

  Future<void> deleteMessage(Event event, {String? reason}) => ref
      .watch(ClientController.provider.notifier)
      .redactEvent(
        RedactEventRequest(
          eventId: event.eventId,
          roomId: roomId,
          reason: reason,
        ),
      );

  Future<bool> loadOlder() async {
    final timelineKeys = ref
        .read(RoomsController.provider.select((value) => value[roomId]))
        ?.timeline
        .keys;
    final response = await ref
        .watch(ClientController.provider.notifier)
        .paginate(
          .new(
            roomId: roomId,
            maxTimelineId: timelineKeys?.isNotEmpty == true
                ? timelineKeys?.reduce(min)
                : null,
          ),
        );

    ref
        .watch(RoomsController.provider.notifier)
        .update(
          IMap({
            roomId: Room(
              events: IMap.fromIterable(
                response.events.addAll(response.relatedEvents),
                keyMapper: (event) => event.rowId,
                valueMapper: (event) => event,
              ),
              hasMore: response.hasMore,
              timeline: IMap.fromIterable(
                response.events,
                keyMapper: (event) => event.timelineRowId,
                valueMapper: (event) => event.rowId,
              ),
            ),
          }),
          .new(),
        );

    return response.hasMore;
  }

  Future<void> send(
    String text, {
    bool shouldMention = true,
    required IList<Tag> tags,
    required RelationType relationType,
    Event? relation,
  }) async {
    var taggedMessage = text;

    for (final tag in tags) {
      final escaped = RegExp.escape(tag.id);
      final pattern = RegExp(r"@+(" + escaped + r")(#[^#]*#)?");

      taggedMessage = taggedMessage.replaceAllMapped(
        pattern,
        (match) => match.group(1)!,
      );
    }

    final client = ref.watch(ClientController.provider.notifier);
    final event = await client.sendMessage(
      SendMessageRequest(
        roomId: roomId,
        mentions: Mentions(
          userIds: [
            if (shouldMention == true &&
                relation != null &&
                relationType == RelationType.reply)
              relation.sender,
          ].toIList(),
          room: taggedMessage.contains("@room"),
        ),
        text: taggedMessage,
        relation: relation == null
            ? null
            : .new(eventId: relation.eventId, relationType: relationType),
      ),
    );

    ref
        .watch(RoomsController.provider.notifier)
        .update(
          .new({
            roomId: .new(
              events: .new({event.rowId: event}),
              sticky: .new({event.rowId}),
            ),
          }),
          .new(),
        );
  }

  Future<void> removeReaction(
    String reaction,
    Event event,
    String userId,
  ) async {
    final client = ref.watch(ClientController.provider.notifier);
    final allReactionEvents = await client.getRelatedEvents(
      .new(
        roomId: roomId,
        eventId: event.eventId,
        relationType: "m.annotation",
      ),
    );

    final reactionEvents = allReactionEvents
        ?.where((event) => event.redactedBy == null)
        .toIList();

    final reactionEvent = reactionEvents?.firstWhereOrNull(
      (event) => switch (event.content) {
        ReactionContent(:final key) =>
          key == reaction && event.sender == userId,
        _ => false,
      },
    );

    if (reactionEvent != null) {
      await ref
          .watch(ClientController.provider.notifier)
          .redactEvent(.new(eventId: reactionEvent.eventId, roomId: roomId));
    }
  }

  Future<void> sendReaction(String reaction, Event event) async {
    final client = ref.watch(ClientController.provider.notifier);

    await client.sendEvent(
      .new(
        roomId: roomId,
        type: EventType.reaction.type,
        content: {
          "m.relates_to": {
            "event_id": event.eventId,
            "rel_type": "m.annotation",
            "key": reaction,
          },
        },
        synchronous: true,
        disableEncryption: true,
      ),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, IList<Event>, String>(
        RoomChatController.new,
      );
}
