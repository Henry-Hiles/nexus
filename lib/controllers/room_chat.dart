import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/attachment.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/reaction.dart";
import "package:nexus/models/direction.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/redact_event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/send_message.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/room_chat.dart";

typedef ChatParams = ({String roomId, int? contextualEvent});

class RoomChatController(final ChatParams info)
    extends AsyncNotifier<RoomChat?> {
  @override
  Future<RoomChat?> build() async {
    final client = ref.read(ClientController.provider.notifier);
    final room = ref.read(
      RoomsController.provider.select((rooms) => rooms[info.roomId]),
    );

    if (room == null) return null;

    if (!room.hasFetchedState) {
      final state = await client.getRoomState(.new(roomId: info.roomId));
      ref.read(RoomsController.provider.notifier).addState(info.roomId, state);
    }

    final timeline = room.timeline
        .toEntryIList(compare: (a, b) => (a?.key ?? 0).compareTo(b?.key ?? 0))
        .map((e) => e.value)
        .toIList()
        .addAll(room.clientSticky)
        .nonNulls
        .toIList();
    if (info.contextualEvent == null ||
        timeline.contains(info.contextualEvent)) {
      ref.watch(
        RoomsController.provider.select(
          (rooms) =>
              (rooms[info.roomId]?.timeline, rooms[info.roomId]?.clientSticky),
        ),
      );

      return .new(
        timeline: timeline,
        hasMoreBackward: room.hasMore,
        hasMoreForward: false,
      );
    } else {
      final context = await client.getEventContext(
        .new(
          roomId: info.roomId,
          eventId: room.events[info.contextualEvent!]!.eventId,
        ),
      );

      final events = context.before.add(context.event).addAll(context.after);
      ref
          .read(RoomsController.provider.notifier)
          .update(
            .new({
              info.roomId: Room(
                events: IMap.fromIterable(
                  events,
                  keyMapper: (event) => event.rowId,
                ),
              ),
            }),
            .new(),
          );
      return .new(
        timeline: .new(events.map((element) => element.rowId)),
        hasMoreBackward: true,
        hasMoreForward: true,
        historicalData: .new(start: context.start, end: context.end),
      );
    }
  }

  Future<void> deleteMessage(Event event, {String? reason}) => ref
      .watch(ClientController.provider.notifier)
      .redactEvent(
        RedactEventRequest(
          eventId: event.eventId,
          roomId: info.roomId,
          reason: reason,
        ),
      );

  Future<void> paginate(Direction direction) async {
    if (state.isLoading) return;

    final chat = await future;

    if (direction == .forward
        ? chat?.hasMoreForward == false
        : chat?.hasMoreBackward == false) {
      return;
    }

    state = .loading();

    final client = ref.read(ClientController.provider.notifier);

    if (chat?.historicalData == null) {
      final timelineKeys = ref
          .read(RoomsController.provider.select((value) => value[info.roomId]))
          ?.timeline
          .keys;
      final response = await client.paginate(
        .new(
          roomId: info.roomId,
          maxTimelineId: timelineKeys?.isNotEmpty == true
              ? timelineKeys?.reduce(min)
              : null,
        ),
      );

      if (response.events.isEmpty) {
        state = .data(state.value);
      }

      ref
          .read(RoomsController.provider.notifier)
          .update(
            IMap({
              info.roomId: Room(
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
    } else {
      final paginationResponse = await client.paginateManual(
        .new(
          roomId: info.roomId,
          direction: direction,
          since: direction == .forward
              ? chat!.historicalData!.end
              : chat!.historicalData!.start,
        ),
      );

      ref
          .read(RoomsController.provider.notifier)
          .update(
            .new({
              info.roomId: Room(
                events: IMap.fromIterable(
                  paginationResponse.events,
                  keyMapper: (event) => event.rowId,
                ),
              ),
            }),
            .new(),
          );

      final eventRowIds = paginationResponse.events
          .map((element) => element.rowId)
          .toIList();

      state = .data(
        .new(
          timeline: direction == .forward
              ? chat.timeline.addAll(eventRowIds)
              : eventRowIds.addAll(chat.timeline),
          hasMoreForward:
              direction == .forward && paginationResponse.nextBatch == null
              ? false
              : chat.hasMoreForward,
          hasMoreBackward:
              direction == .backward && paginationResponse.nextBatch == null
              ? false
              : chat.hasMoreBackward,
          historicalData: chat.historicalData?.copyWith(
            start:
                (direction == .backward
                    ? paginationResponse.nextBatch
                    : null) ??
                chat.historicalData!.start,
            end:
                (direction == .forward ? paginationResponse.nextBatch : null) ??
                chat.historicalData!.end,
          ),
        ),
      );
    }
  }

  Future<void> send(
    String text, {
    bool shouldMention = true,
    required IList<Tag> tags,
    required RelationType relationType,
    Event? relation,
  }) async {
    Content? baseContent;
    if (relationType == .edit) {
      baseContent = relation?.content;
    } else {
      final provider = AttachmentController.provider(info.roomId);
      baseContent = ref.read(provider)?.$2;
      ref.invalidate(provider);
    }

    var taggedMessage = text;

    for (final tag in tags) {
      final escaped = RegExp.escape(tag.id);
      final pattern = RegExp(r"@+(" + escaped + r")(#[^#]*#)?");

      taggedMessage = taggedMessage.replaceAllMapped(
        pattern,
        (match) => match.group(1)!,
      );
    }

    final client = ref.read(ClientController.provider.notifier);
    final event = await client.sendMessage(
      SendMessageRequest(
        roomId: info.roomId,
        baseContent: baseContent,
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
        .read(RoomsController.provider.notifier)
        .update(
          .new({
            info.roomId: .new(
              events: .new({event.rowId: event}),
              clientSticky: .new({event.rowId}),
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
    final client = ref.read(ClientController.provider.notifier);
    final allReactionEvents = await client.getRelatedEvents(
      .new(
        roomId: info.roomId,
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
          .redactEvent(
            .new(eventId: reactionEvent.eventId, roomId: info.roomId),
          );
    }
  }

  Future<void> sendReaction(String reaction, Event event) async {
    final client = ref.read(ClientController.provider.notifier);

    await client.sendEvent(
      .new(
        roomId: info.roomId,
        type: EventType.reaction.type,
        content: ReactionContent(key: reaction),
        synchronous: true,
        disableEncryption: true,
        relatesTo: event.eventId,
        relationType: "m.annotation",
      ),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, RoomChat?, ChatParams>(
        RoomChatController.new,
      );
}
