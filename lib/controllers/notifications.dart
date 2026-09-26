import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/event.dart";

typedef NotificationsRequest = (UnreadType? unreadType, String? roomId);

class NotificationsController([final NotificationsRequest? request])
    extends AsyncNotifier<IList<Event>> {
  @override
  Future<IList<Event>> build() async {
    final client = ref.read(ClientController.provider.notifier);

    final (unreadType, roomId) = request ?? (null, null);

    return await client.getMentions(
      .new(
        maxTimestamp: .now(),
        unreadType: unreadType ?? .highlight,
        roomId: roomId,
      ),
    );
  }

  Future<void> loadOlder() async {
    final currentNotifications = await future;
    state = .loading();
    state = await .guard(() async {
      final lastTs = currentNotifications.lastOrNull?.timestamp;
      if (lastTs == null) return const .empty();

      final client = ref.read(ClientController.provider.notifier);
      final (unreadType, roomId) = request ?? (null, null);

      final newNotifications = await client.getMentions(
        .new(
          maxTimestamp: lastTs,
          unreadType: unreadType ?? .highlight,
          roomId: roomId,
        ),
      );

      return currentNotifications.addAll(newNotifications);
    });
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        NotificationsController,
        IList<Event>,
        NotificationsRequest?
      >(NotificationsController.new);
}
