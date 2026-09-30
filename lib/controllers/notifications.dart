import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/event.dart";

typedef NotificationsRequest = (UnreadType? unreadType, String? roomId);

class NotificationsController(final NotificationsRequest request)
    extends AsyncNotifier<IList<(int, String)>> {
  void storeEvents(Iterable<Event> events) => ref
      .read(RoomsController.provider.notifier)
      .update(
        .new(
          events
              .groupListsBy((event) => event.roomId)
              .map(
                (roomId, roomEvents) => .new(
                  roomId,
                  .new(
                    events: IMap.fromIterable(
                      roomEvents,
                      keyMapper: (event) => event.rowId,
                    ),
                  ),
                ),
              ),
        ),
      );

  @override
  Future<IList<(int, String)>> build() async {
    final client = ref.read(ClientController.provider.notifier);

    final (unreadType, roomId) = request;

    final mentions = await client.getMentions(
      .new(
        maxTimestamp: .now(),
        unreadType: unreadType ?? .highlight,
        roomId: roomId,
      ),
    );

    storeEvents(mentions);

    return .new(mentions.map((event) => (event.rowId, event.roomId)));
  }

  Future<void> loadOlder() async {
    final currentNotifications = await future;
    state = .loading();
    state = await .guard(() async {
      final lastNotification = currentNotifications.lastOrNull;
      final lastTs = lastNotification == null
          ? null
          : ref.watch(
              RoomsController.provider.select(
                (rooms) => rooms[lastNotification.$2]
                    ?.events[lastNotification.$1]
                    ?.timestamp,
              ),
            );

      if (lastTs == null) return currentNotifications;

      final client = ref.read(ClientController.provider.notifier);
      final (unreadType, roomId) = request;

      final newNotifications = await client.getMentions(
        .new(
          maxTimestamp: lastTs,
          unreadType: unreadType ?? .highlight,
          roomId: roomId,
        ),
      );

      storeEvents(newNotifications);

      return currentNotifications.addAll(
        newNotifications.map((event) => (event.rowId, event.roomId)),
      );
    });
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        NotificationsController,
        IList<(int, String)>,
        NotificationsRequest
      >(NotificationsController.new);
}
