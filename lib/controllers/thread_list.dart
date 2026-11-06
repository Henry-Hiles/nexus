import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";

class ThreadListController(final String roomId) extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => fetch(null);

  Future<String?> fetch(String? since) async {
    final threads = await ref
        .read(ClientController.provider.notifier)
        .getThreads(.new(roomId: roomId, since: since));
    ref
        .read(RoomsController.provider.notifier)
        .storeEvents(threads.events.addAll(threads.relatedEvents));

    return threads.nextBatch;
  }

  Future<void> loadMore() async {
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
      .autoDispose<ThreadListController, String?, String>(
        ThreadListController.new,
      );
}
