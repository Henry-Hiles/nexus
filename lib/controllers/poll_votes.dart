import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/event_id_is_fake.dart";
import "package:nexus/models/configs/event.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/poll_end.dart";
import "package:nexus/models/content/poll_response.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/poll_votes.dart";

class PollVotesController(final EventConfig config)
    extends AsyncNotifier<PollVotes> {
  @override
  Future<PollVotes> build() async {
    // Only what's needed, so e.g. reactions don't cause refetches
    final (poll, localRelated) = ref.watch(
      RoomsController.provider.select((rooms) {
        final room = rooms[config.roomId];
        final event = room?.events[config.eventRowId];
        if (room == null || event == null) {
          return (null, const IList<Event>.empty());
        }

        final edited = event.lastEditRowId == 0
            ? null
            : room.events[event.lastEditRowId];

        return (
          (
            eventId: event.eventId,
            sender: event.sender,
            // Edits can change the answers
            content: (edited ?? event).content,
          ),
          (room.relations[event.eventId] ?? const ISet<int>.empty())
              .map((rowId) => room.events[rowId])
              .nonNulls
              .where((related) => related.relationType == "m.reference")
              .toIList(),
        );
      }),
    );
    final powerLevels = ref.watch(
      RoomPowerLevelsController.provider(config.roomId),
    );

    if (poll == null) return const PollVotes();
    final PollStart(:answers, :selectionLimit) = switch (poll.content) {
      PollStartContent(:final poll) => poll,
      _ => const PollStart(),
    };

    final fetched = await ref
        .read(ClientController.provider.notifier)
        .getRelatedEvents(
          .new(
            roomId: config.roomId,
            eventId: poll.eventId,
            relationType: "m.reference",
          ),
        );

    final related =
        IMap.fromIterable(
              (fetched ?? const IList.empty()).addAll(localRelated),
              keyMapper: (event) => event.rowId,
              valueMapper: (event) => event,
            ).values
            // gomuks' database has unsent local echoes too
            .where((event) => event.redactedBy == null && !event.eventId.isFake)
            .toIList();

    final end = related
        .where(
          (event) =>
              event.content is PollEndContent &&
              powerLevels.canEndPoll(event.sender, pollSender: poll.sender),
        )
        .sortedBy((event) => event.timestamp)
        .firstOrNull;
    final endedAt = end?.timestamp;

    bool beforeEnd(Event event) =>
        endedAt == null || !event.timestamp.isAfter(endedAt);

    final answerIds = answers.map((answer) => answer.id).toISet();

    return .new(
      endEventId: end?.eventId,
      undecryptable: related
          .where(
            (event) => event.content is EncryptedContent && beforeEnd(event),
          )
          .length,
      // Each user's latest response before the end counts, even if invalid
      votes: related
          .where(
            (event) =>
                event.type == EventType.pollResponse.type && beforeEnd(event),
          )
          .toIList()
          .sort((a, b) => a.timestamp.compareTo(b.timestamp))
          .fold(const .empty(), (votes, event) {
            // Truncated before removing duplicates, as MSC3381 specifies
            final picked = switch (event.content) {
              PollResponseContent(:final answers) =>
                answers.take(selectionLimit).toISet(),
              _ => null,
            };

            return votes.add(
              event.sender,
              // Spoiled responses count as no answers
              picked != null && picked.every(answerIds.contains)
                  ? picked.toIList()
                  : const .empty(),
            );
          }),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<PollVotesController, PollVotes, EventConfig>(
        PollVotesController.new,
      );
}
