import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";

typedef ThreadParams = ({String roomId, String threadRoot});

/// Loads a thread's replies from the server, newest first, storing them. Its
/// state is the token for older replies, or null if there are none.
class ThreadRepliesController(final ThreadParams thread)
    extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => fetch(null);

  Future<String?> fetch(String? since) async {
    final response = await ref
        .read(ClientController.provider.notifier)
        .paginateManual(
          .new(
            roomId: thread.roomId,
            threadRoot: thread.threadRoot,
            since: since,
            direction: .backward,
          ),
        );
    ref
        .read(RoomsController.provider.notifier)
        .storeEvents(response.events.addAll(response.relatedEvents));

    return response.nextBatch;
  }

  Future<void> loadOlder() async {
    final since = await future;
    if (state.isLoading || since == null) return;

    state = .loading();
    try {
      state = .data(await fetch(since));
    } catch (_) {
      state = .data(since);
      rethrow;
    }
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<ThreadRepliesController, String?, ThreadParams>(
        ThreadRepliesController.new,
      );
}
