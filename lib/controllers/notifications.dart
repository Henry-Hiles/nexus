import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/event.dart";

typedef NotificationsRequest = (UnreadType? unreadType, String? roomId);

class NotificationsController([final NotificationsRequest? request])
    extends AsyncNotifier<IList<(int, String)>> {
  static const virtualRoomId = "!notifications";

  @override
  Future<IList<(int, String)>> build() async {
    final client = ref.read(ClientController.provider.notifier);

    final (unreadType, roomId) = request ?? (null, null);

    final mentions = await client.getMentions(
      .new(
        maxTimestamp: .now(),
        unreadType: unreadType ?? .highlight,
        roomId: roomId,
      ),
    );

    ref
        .watch(RoomsController.provider.notifier)
        .update(
          .new({
            virtualRoomId: .new(
              events: IMap.fromIterable(
                mentions,
                keyMapper: (event) => event.rowId,
              ),
            ),
          }),
          .new(),
        );

    return .new(mentions.map((event) => (event.rowId, event.roomId)));
  }

  Future<void> loadOlder() async {
    final currentNotifications = await future;
    state = .loading();
    state = await .guard(() async {
      final lastNotification = currentNotifications.lastOrNull?.$1;
      final lastTs = lastNotification == null
          ? null
          : ref.watch(
              RoomsController.provider.select(
                (rooms) =>
                    rooms[virtualRoomId]?.events[lastNotification]?.timestamp,
              ),
            );

      if (lastTs == null) return currentNotifications;

      final client = ref.read(ClientController.provider.notifier);
      final (unreadType, roomId) = request ?? (null, null);

      final newNotifications = await client.getMentions(
        .new(
          maxTimestamp: lastTs,
          unreadType: unreadType ?? .highlight,
          roomId: roomId,
        ),
      );

      ref
          .watch(RoomsController.provider.notifier)
          .update(
            .new({
              virtualRoomId: .new(
                events: IMap.fromIterable(
                  newNotifications,
                  keyMapper: (event) => event.rowId,
                ),
              ),
            }),
            .new(),
          );

      return currentNotifications.addAll(
        newNotifications.map((event) => (event.rowId, event.roomId)),
      );
    });
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        NotificationsController,
        IList<(int, String)>,
        NotificationsRequest?
      >(NotificationsController.new);
}
