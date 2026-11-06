import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/helpers/extensions/event_id_is_fake.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

typedef ThreadInfo = ({int count, Event? latest});
typedef Thread = ({Event root, ThreadInfo info});

extension ThreadEvents on Room {
  /// The threads in the loaded events, most recently active first.
  IList<Thread> get threads {
    DateTime lastActive(Thread thread) =>
        thread.info.latest?.timestamp ?? thread.root.timestamp;

    return events.values
        .where((event) => event.threadCount > 0)
        .map((root) => (root: root, info: thread(root)))
        .sorted((a, b) => lastActive(b).compareTo(lastActive(a)))
        .toIList();
  }

  /// The events in the thread from [threadRoot], oldest first, without the
  /// root itself.
  IList<Event> threadEvents(String threadRoot) =>
      (relations[threadRoot] ?? const .empty())
          .map((rowId) => events[rowId])
          .nonNulls
          .where(
            (event) =>
                event.threadRoot == threadRoot &&
                (!event.eventId.isFake || clientSticky.contains(event.rowId)),
          )
          .sorted((a, b) => a.timestamp.compareTo(b.timestamp))
          .toIList();

  /// How many replies the thread from [root] has, and its latest event, from
  /// gomuks' aggregate on it
  ThreadInfo thread(Event root) =>
      (count: root.threadCount, latest: events[root.threadLatestRowId]);

  /// The latest event in the thread from [threadRoot], if it's loaded.
  Event? latestThreadEvent(String threadRoot) => switch (eventIds[threadRoot]) {
    final rowId? => switch (events[rowId]) {
      final root? => thread(root).latest,
      null => null,
    },
    null => null,
  };
}
