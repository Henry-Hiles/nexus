import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/attachment.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/thread_replies.dart";
import "package:nexus/helpers/extensions/is_media.dart";
import "package:nexus/helpers/extensions/send_failed.dart";
import "package:nexus/helpers/extensions/thread_events.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/content/bot_command.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/content/poll_end.dart";
import "package:nexus/models/content/poll_response.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/content/reaction.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/direction.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/paginate_manual.dart";
import "package:nexus/models/requests/redact_event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/requests/send_message.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/room_chat.dart";

typedef ChatParams = ({
  String roomId,
  int? contextualEvent,
  String? threadRoot,
});

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

    if (info.threadRoot case final threadRoot?
        when info.contextualEvent == null) {
      final nextBatch = await ref.watch(
        ThreadRepliesController.provider((
          roomId: info.roomId,
          threadRoot: threadRoot,
        )).future,
      );

      return .new(
        timeline: ref.watch(RoomsController.provider.select(threadTimeline)),
        hasMoreBackward: nextBatch != null,
        hasMoreForward: false,
      );
    }

    if (info.threadRoot == null) {
      final timeline = room.timeline
          .toEntryIList(compare: (a, b) => (a?.key ?? 0).compareTo(b?.key ?? 0))
          .map((e) => e.value)
          .toIList()
          .addAll(room.clientSticky)
          .nonNulls
          // Threads are shown from their root instead
          .where((rowId) => room.events[rowId]?.threadRoot == null)
          .toIList();

      if (info.contextualEvent == null ||
          timeline.contains(info.contextualEvent)) {
        ref.watch(
          RoomsController.provider.select(
            (rooms) => (
              rooms[info.roomId]?.timeline,
              rooms[info.roomId]?.clientSticky,
            ),
          ),
        );

        return .new(
          timeline: timeline,
          hasMoreBackward: room.hasMore,
          hasMoreForward: false,
        );
      }
    }

    final context = await client.getEventContext(
      .new(
        roomId: info.roomId,
        eventId: room.events[info.contextualEvent!]!.eventId,
      ),
    );

    final contextEvents = context.before.reversed
        .toIList()
        .add(context.event)
        .addAll(context.after);
    ref
        .read(RoomsController.provider.notifier)
        .storeEvents(contextEvents.addAll(context.relatedEvents));

    if (info.threadRoot case final threadRoot?) {
      final (older, newer) = await (
        client.paginateManual(
          .new(
            roomId: info.roomId,
            threadRoot: threadRoot,
            since: context.start,
            direction: .backward,
          ),
        ),
        client.paginateManual(
          .new(
            roomId: info.roomId,
            threadRoot: threadRoot,
            since: context.end,
            direction: .forward,
          ),
        ),
      ).wait;
      final rootRowId = await threadRootBefore(older);
      ref
          .read(RoomsController.provider.notifier)
          .storeEvents(
            older.events
                .addAll(older.relatedEvents)
                .addAll(newer.events)
                .addAll(newer.relatedEvents),
          );

      return .new(
        timeline: .new([?rootRowId])
            .addAll(
              // Paginating backwards gives the newest first
              older.events.reversed
                  .addAll(
                    contextEvents.where(
                      (event) => event.threadRoot == threadRoot,
                    ),
                  )
                  .addAll(newer.events)
                  .map((event) => event.rowId),
            )
            .removeDuplicates(),
        hasMoreBackward: older.nextBatch != null,
        hasMoreForward: newer.nextBatch != null,
        historicalData: .new(
          start: older.nextBatch ?? "",
          end: newer.nextBatch ?? "",
        ),
      );
    }

    return .new(
      timeline: .new(
        contextEvents
            .where((event) => event.threadRoot == null)
            .map((event) => event.rowId),
      ),
      hasMoreBackward: true,
      hasMoreForward: true,
      historicalData: .new(start: context.start, end: context.end),
    );
  }

  /// The thread's root, which comes before all of its events, if paginating
  /// backwards to [older] reached the start of the thread.
  Future<int?> threadRootBefore(PaginateManual older) async =>
      switch (info.threadRoot) {
        final threadRoot? when older.nextBatch == null => await ref.read(
          EventController.provider(
            .new(roomId: info.roomId, eventId: threadRoot),
          ).future,
        ),
        _ => null,
      };

  /// The thread's root, then its events, if this is a thread's chat.
  IList<int> threadTimeline(IMap<String, Room> rooms) =>
      switch ((rooms[info.roomId], info.threadRoot)) {
        (final room?, final threadRoot?) => .new([
          ?room.eventIds[threadRoot],
          ...room.threadEvents(threadRoot).map((event) => event.rowId),
        ]),
        _ => const .empty(),
      };

  Relation? replyRelation(Event? replied) =>
      switch (info.threadRoot ?? replied?.threadRoot) {
        null =>
          replied == null
              ? null
              : .new(eventId: replied.eventId, relationType: .reply),
        final threadRoot => .new(
          eventId:
              replied?.eventId ??
              ref
                  .read(RoomsController.provider)[info.roomId]
                  ?.latestThreadEvent(threadRoot)
                  ?.eventId ??
              threadRoot,
          relationType: .reply,
          threadRoot: threadRoot,
          isFallingBack: replied == null,
        ),
      };

  Future<void> deleteMessage(Event event, {String? reason}) => ref
      .read(ClientController.provider.notifier)
      .redactEvent(
        RedactEventRequest(
          eventId: event.eventId,
          roomId: info.roomId,
          reason: reason,
        ),
      );

  void hideClientSticky(int eventRowId) => ref
      .read(RoomsController.provider.notifier)
      .update(
        .new({
          info.roomId: Room(
            resetClientSticky: true,
            clientSticky:
                ref
                    .read(
                      RoomsController.provider.select(
                        (rooms) => rooms[info.roomId]?.clientSticky,
                      ),
                    )
                    ?.remove(eventRowId) ??
                .new(),
          ),
        }),
      );

  Future<void> paginate(Direction direction) async {
    if (state.isLoading) return;

    final chat = await future;

    if (direction == .forward
        ? chat?.hasMoreForward == false
        : chat?.hasMoreBackward == false) {
      return;
    }

    if ((info.threadRoot, chat) case (final threadRoot?, final chat?)
        when chat.historicalData == null) {
      return ref
          .read(
            ThreadRepliesController.provider((
              roomId: info.roomId,
              threadRoot: threadRoot,
            )).notifier,
          )
          .loadOlder();
    }

    state = .loading();

    final client = ref.read(ClientController.provider.notifier);

    try {
      if (chat?.historicalData == null) {
        final timelineKeys = ref
            .read(
              RoomsController.provider.select((value) => value[info.roomId]),
            )
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
          state = .data(chat);
        }

        ref
            .read(RoomsController.provider.notifier)
            .update(
              .new({
                info.roomId: .new(
                  // ignore: unused_result - I am using it you donkey
                  events: .fromIterable(
                    response.events.addAll(response.relatedEvents),
                    keyMapper: (event) => event.rowId,
                    valueMapper: (event) => event,
                  ),
                  hasMore: response.hasMore,
                  receipts: response.receipts,
                  // ignore: unused_result - I am using it you donkey
                  timeline: .fromIterable(
                    response.events,
                    keyMapper: (event) => event.timelineRowId,
                    valueMapper: (event) => event.rowId,
                  ),
                ),
              }),
            );
      } else {
        final paginationResponse = await client.paginateManual(
          .new(
            roomId: info.roomId,
            threadRoot: info.threadRoot,
            direction: direction,
            since: direction == .forward
                ? chat!.historicalData!.end
                : chat!.historicalData!.start,
          ),
        );

        ref
            .read(RoomsController.provider.notifier)
            .storeEvents(
              paginationResponse.events.addAll(
                paginationResponse.relatedEvents,
              ),
            );

        final rootRowId = direction == .backward
            ? await threadRootBefore(paginationResponse)
            : null;
        final eventRowIds = [
          ?rootRowId,
          ...(direction == .forward
                  ? paginationResponse.events
                  : paginationResponse.events.reversed)
              .where((event) => event.threadRoot == info.threadRoot)
              .map((element) => element.rowId),
        ].lock;

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
                  (direction == .forward
                      ? paginationResponse.nextBatch
                      : null) ??
                  chat.historicalData!.end,
            ),
          ),
        );
      }
    } catch (_) {
      state = .data(chat);
      rethrow;
    }
  }

  Future<void> send(
    String text, {
    bool shouldMention = true,
    required IList<Tag> tags,
    required RelationType relationType,
    int? relatedEventRowId,
  }) async {
    final events = ref.read(RoomsController.provider)[info.roomId]?.events;
    final relatedEvent = relatedEventRowId == null
        ? null
        : events?[relatedEventRowId];

    final ComposerParams composer = (
      roomId: info.roomId,
      threadRoot: info.threadRoot,
    );
    final attachmentProvider = AttachmentController.provider(composer);
    final attachment = ref.read(attachmentProvider)?.$2;
    ref.invalidate(attachmentProvider);

    // Edits of media use the attachment, which starts as the current media
    final latestContent = relatedEvent == null
        ? null
        : (events?[relatedEvent.lastEditRowId] ?? relatedEvent).content;
    final baseContent =
        attachment ??
        (relationType == .edit && latestContent?.isMedia == false
            ? latestContent
            : null);

    // Replaces each formatted tag, like "@id#name#", with its ID
    final taggedMessage = tags.fold(
      text,
      (message, tag) => message.replaceAllMapped(
        RegExp(r"@+(" + RegExp.escape(tag.id) + r")(#[^#]*#)?"),
        (match) => match.group(1)!,
      ),
    );

    final client = ref.read(ClientController.provider.notifier);
    final event = await client.sendMessage(
      SendMessageRequest(
        roomId: info.roomId,
        baseContent: baseContent,
        mentions: Mentions(
          userIds: [
            if (shouldMention && relatedEvent != null && relationType == .reply)
              relatedEvent.sender,
          ].toIList(),
          room: taggedMessage.contains("@room"),
        ),
        text: taggedMessage,
        relation: relationType == .edit && relatedEvent != null
            ? .new(eventId: relatedEvent.eventId, relationType: .edit)
            : replyRelation(relatedEvent),
      ),
    );

    addSent(event);
  }

  /// Shows [event], which was just sent, until it comes down sync.
  void addSent(Event? event) {
    if (event case final event?) {
      ref
          .read(RoomsController.provider.notifier)
          .update(
            .new({
              info.roomId: .new(
                events: .new({event.rowId: event}),
                clientSticky: .new({event.rowId}),
              ),
            }),
          );
    }
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

    final reactionEvent = allReactionEvents?.firstWhereOrNull(
      (event) =>
          event.redactedBy == null &&
          switch (event.content) {
            ReactionContent(:final key) =>
              key == reaction && event.sender == userId,
            _ => false,
          },
    );

    if (reactionEvent != null) {
      await client.redactEvent(
        .new(eventId: reactionEvent.eventId, roomId: info.roomId),
      );
    }
  }

  /// Reacts to [event] with [reaction], which is an mxc URL for custom emoji,
  /// with their [shortcode].
  Future<void> sendReaction(
    String reaction,
    Event event, {
    String? shortcode,
  }) async {
    final client = ref.read(ClientController.provider.notifier);

    await client.sendEvent(
      .new(
        roomId: info.roomId,
        type: EventType.reaction.type,
        // Wrapped in colons, like other clients send it
        content: ReactionContent(
          key: reaction,
          shortcode: shortcode == null ? null : ":$shortcode:",
        ),
        synchronous: true,
        disableEncryption: true,
        relatesTo: event.eventId,
        relationType: "m.annotation",
      ),
    );
  }

  /// Sends [content], as a reply to [repliedEventRowId] if set.
  Future<void> sendWithReply(
    EventType type,
    Content content, {
    bool shouldMention = true,
    int? repliedEventRowId,
  }) async {
    final repliedEvent = repliedEventRowId == null
        ? null
        : ref.read(
            RoomsController.provider.select(
              (rooms) => rooms[info.roomId]?.events[repliedEventRowId],
            ),
          );

    final event = await ref
        .read(ClientController.provider.notifier)
        .sendEvent(
          .new(
            roomId: info.roomId,
            type: type.type,
            content: content,
            mentions: Mentions(
              userIds: [
                if (shouldMention && repliedEvent != null) repliedEvent.sender,
              ].toIList(),
            ),
            reply: replyRelation(repliedEvent),
          ),
        );

    addSent(event);
  }

  /// Sends [image] as a sticker, as a reply to [repliedEventRowId] if set.
  Future<void> sendSticker(
    String shortcode,
    PackImage image, {
    bool shouldMention = true,
    int? repliedEventRowId,
  }) => sendWithReply(
    .sticker,
    StickerContent(
      body: image.body ?? shortcode,
      info: image.info ?? const .new(),
      url: image.url,
    ),
    shouldMention: shouldMention,
    repliedEventRowId: repliedEventRowId,
  );

  Future<void> sendPoll(
    PollStart poll, {
    bool shouldMention = true,
    int? repliedEventRowId,
  }) => sendWithReply(
    .pollStart,
    PollStartContent(poll: poll),
    shouldMention: shouldMention,
    repliedEventRowId: repliedEventRowId,
  );

  Future<void> sendLocation(
    LocationMessageContent location, {
    bool shouldMention = true,
    int? repliedEventRowId,
  }) => sendWithReply(
    .message,
    location,
    shouldMention: shouldMention,
    repliedEventRowId: repliedEventRowId,
  );

  Future<void> sendBotCommand(
    BotCommandDraft draft, {
    int? repliedEventRowId,
  }) async {
    final repliedEvent = repliedEventRowId == null
        ? null
        : ref
              .read(RoomsController.provider)[info.roomId]
              ?.events[repliedEventRowId];

    final event = await ref
        .read(ClientController.provider.notifier)
        .sendMessage(
          .new(
            roomId: info.roomId,
            text: "",
            baseContent: BotCommandMessageContent(
              body: draft.body,
              command: draft.input,
            ),
            mentions: .new(userIds: [draft.command.sender].lock),
            relation: replyRelation(repliedEvent),
          ),
        );

    addSent(event);
  }

  /// Completes once the event has come down sync.
  Future<void> sendPollReference(
    Event poll,
    EventType type,
    Content content,
  ) async {
    // The end event lands in the timeline and rebuilds this, so no ref after awaiting
    final rooms = ref.read(RoomsController.provider.notifier);
    final event = await ref
        .read(ClientController.provider.notifier)
        .sendEvent(
          .new(
            roomId: info.roomId,
            type: type.type,
            content: content,
            relatesTo: poll.eventId,
            relationType: "m.reference",
            synchronous: true,
          ),
        );

    if (event.sendFailed) throw Exception(event.sendError);

    await rooms.awaitEvent(info.roomId, event.eventId);
  }

  /// An empty [answers] removes the vote.
  Future<void> votePoll(Event poll, IList<String> answers) => sendPollReference(
    poll,
    .pollResponse,
    PollResponseContent(answers: answers),
  );

  Future<void> endPoll(Event poll) =>
      sendPollReference(poll, .pollEnd, const PollEndContent());

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, RoomChat?, ChatParams>(
        RoomChatController.new,
      );
}
