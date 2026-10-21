import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/requests/search.dart";

typedef EventSearchParams = ({String roomId, String query});
typedef EventSearchResults = ({IList<int> rowIds, String? nextBatch});

class EventSearchController(final EventSearchParams info)
    extends AsyncNotifier<EventSearchResults> {
  // We could have a mode without this for power users in the future
  static String toFtsQuery(String query) => query
      .split(RegExp(r"\s+"))
      .where((word) => word.isNotEmpty)
      .map((word) => '"${word.replaceAll('"', '""')}"*')
      .join(" ");

  @override
  Future<EventSearchResults> build() async {
    if (info.query.trim().isEmpty) {
      return (rowIds: IList<int>(), nextBatch: null);
    }

    final client = ref.read(ClientController.provider.notifier);

    final encrypted = ref.read(
      RoomsController.provider.select(
        (rooms) => rooms[info.roomId]?.metadata?.encryptionEvent != null,
      ),
    );
    final request = SearchRequest(
      searchTerm: encrypted ? toFtsQuery(info.query) : info.query,
      roomIds: .new([info.roomId]),
    );
    final response = encrypted
        ? await client.searchLocal(request)
        : await client.searchServer(request);

    if (!ref.mounted) return (rowIds: IList<int>(), nextBatch: null);

    ref
        .read(RoomsController.provider.notifier)
        .storeEvents(response.events.addAll(response.relatedEvents));

    return (
      rowIds: response.events.map((event) => event.rowId).toIList(),
      nextBatch: response.nextBatch,
    );
  }

  Future<void> paginate() async {
    if (state.isLoading) return;

    final results = await future;
    if (!ref.mounted || results.nextBatch == null) return;

    state = .loading();

    final encrypted = ref.read(
      RoomsController.provider.select(
        (rooms) => rooms[info.roomId]?.metadata?.encryptionEvent != null,
      ),
    );

    final request = SearchRequest(
      searchTerm: encrypted ? toFtsQuery(info.query) : info.query,
      roomIds: .new([info.roomId]),
      nextBatch: results.nextBatch,
    );

    final client = ref.read(ClientController.provider.notifier);
    final response = encrypted
        ? await client.searchLocal(request)
        : await client.searchServer(request);

    if (!ref.mounted) return;

    ref
        .read(RoomsController.provider.notifier)
        .storeEvents(response.events.addAll(response.relatedEvents));

    state = .data((
      rowIds: results.rowIds.addAll(
        response.events.map((event) => event.rowId),
      ),
      nextBatch: response.nextBatch,
    ));
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        EventSearchController,
        EventSearchResults,
        EventSearchParams
      >(EventSearchController.new);
}
